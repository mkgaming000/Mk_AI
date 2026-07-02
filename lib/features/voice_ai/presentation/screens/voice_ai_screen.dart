import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../shared/widgets/omni_app_bar.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../settings/providers/settings_provider.dart';

enum VoiceState { idle, recording, processing, speaking, error }

class VoiceSession {
  final String id;
  final String userText;
  final String assistantText;
  final DateTime timestamp;
  const VoiceSession({
    required this.id,
    required this.userText,
    required this.assistantText,
    required this.timestamp,
  });
}

final voiceStateProvider = StateProvider<VoiceState>((ref) => VoiceState.idle);
final voiceHistoryProvider = StateProvider<List<VoiceSession>>((ref) => []);
final voiceTranscriptProvider = StateProvider<String>((ref) => '');
final selectedVoiceProvider = StateProvider<String>((ref) => 'alloy');

class VoiceAIScreen extends ConsumerStatefulWidget {
  const VoiceAIScreen({super.key});

  @override
  ConsumerState<VoiceAIScreen> createState() => _VoiceAIScreenState();
}

class _VoiceAIScreenState extends ConsumerState<VoiceAIScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();
  String? _recordingPath;
  Timer? _recordingTimer;
  int _recordingSeconds = 0;

  static const _voices = [
    {'id': 'alloy', 'name': 'Alloy', 'desc': 'Neutral'},
    {'id': 'echo', 'name': 'Echo', 'desc': 'Male'},
    {'id': 'fable', 'name': 'Fable', 'desc': 'British'},
    {'id': 'onyx', 'name': 'Onyx', 'desc': 'Deep'},
    {'id': 'nova', 'name': 'Nova', 'desc': 'Female'},
    {'id': 'shimmer', 'name': 'Shimmer', 'desc': 'Soft'},
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _recorder.dispose();
    _player.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission required')),
        );
      }
      return;
    }

    final dir = await getTemporaryDirectory();
    _recordingPath =
        p.join(dir.path, 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a');

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000),
      path: _recordingPath!,
    );

    ref.read(voiceStateProvider.notifier).state = VoiceState.recording;
    _recordingSeconds = 0;
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _recordingSeconds++);
    });
  }

  Future<void> _stopRecording() async {
    _recordingTimer?.cancel();
    await _recorder.stop();
    ref.read(voiceStateProvider.notifier).state = VoiceState.processing;
    ref.read(voiceTranscriptProvider.notifier).state = '';
    await _processAudio();
  }

  Future<void> _processAudio() async {
    try {
      if (_recordingPath == null) throw Exception('No recording found');

      final settings = ref.read(settingsProvider);
      final hasOpenAIKey = await ref.read(secureStorageProvider).hasApiKey('openai');
      final hasElevenLabsKey = await ref.read(secureStorageProvider).hasApiKey('elevenlabs');

      if (!hasOpenAIKey && !hasElevenLabsKey) {
        _showNoKeyDialog();
        ref.read(voiceStateProvider.notifier).state = VoiceState.idle;
        return;
      }

      // Step 1: Read audio file
      final audioBytes = await File(_recordingPath!).readAsBytes();

      // Step 2: Transcribe
      String transcript;
      if (hasOpenAIKey) {
        final openAI = ref.read(openAIDatasourceProvider);
        transcript = await openAI.transcribeAudio(
          audioBytes: audioBytes,
          filename: 'audio.m4a',
        );
      } else {
        transcript = 'Voice transcription requires an OpenAI API key.';
      }

      ref.read(voiceTranscriptProvider.notifier).state = transcript;

      // Step 3: Get AI response
      final chatResp = await _getChatResponse(transcript);

      // Step 4: Synthesize speech
      ref.read(voiceStateProvider.notifier).state = VoiceState.speaking;
      final selectedVoice = ref.read(selectedVoiceProvider);

      if (hasOpenAIKey) {
        final openAI = ref.read(openAIDatasourceProvider);
        final ttsBytes = await openAI.textToSpeech(
          text: chatResp,
          voice: selectedVoice,
        );
        await _playSpeech(ttsBytes);
      }

      // Save to history
      final history = [...ref.read(voiceHistoryProvider)];
      history.insert(0, VoiceSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userText: transcript,
        assistantText: chatResp,
        timestamp: DateTime.now(),
      ));
      ref.read(voiceHistoryProvider.notifier).state =
          history.take(20).toList();
      ref.read(voiceStateProvider.notifier).state = VoiceState.idle;
    } catch (e) {
      ref.read(voiceStateProvider.notifier).state = VoiceState.error;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Voice error: $e')),
        );
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          ref.read(voiceStateProvider.notifier).state = VoiceState.idle;
        }
      }
    }
  }

  Future<String> _getChatResponse(String transcript) async {
    final settings = ref.read(settingsProvider);
    final buffer = StringBuffer();

    try {
      await for (final chunk in ref.read(chatRepositoryProvider).streamResponse(
            providerId: settings.defaultProvider,
            modelId: settings.defaultModel,
            messages: [],
            systemPrompt: 'You are a helpful voice assistant. '
                'Keep responses concise and natural for speech — '
                'avoid markdown, bullet points, and code blocks.',
          )) {
        buffer.write(chunk);
      }
      final result = buffer.toString().trim();
      return result.isEmpty
          ? 'I heard you say: $transcript. How can I help?'
          : result;
    } catch (e) {
      return 'I heard: $transcript. (AI response unavailable: $e)';
    }
  }

  Future<void> _playSpeech(List<int> bytes) async {
    final dir = await getTemporaryDirectory();
    final outPath =
        p.join(dir.path, 'tts_${DateTime.now().millisecondsSinceEpoch}.mp3');
    await File(outPath).writeAsBytes(bytes);
    await _player.setFilePath(outPath);
    await _player.play();
    await _player.playerStateStream
        .firstWhere((s) => s.processingState == ProcessingState.completed);
  }

  void _showNoKeyDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('API Key Required'),
        content: const Text(
            'Voice AI requires an OpenAI API key for transcription and speech '
            'synthesis. Add it in Settings → API Keys.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(voiceStateProvider);
    final transcript = ref.watch(voiceTranscriptProvider);
    final history = ref.watch(voiceHistoryProvider);
    final selectedVoice = ref.watch(selectedVoiceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground1 : null,
      appBar: const OmniAppBar(title: 'Voice AI'),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _VoiceOrb(
                    state: voiceState,
                    pulseController: _pulseController,
                    seconds: _recordingSeconds,
                  ),
                  const SizedBox(height: 32),

                  if (transcript.isNotEmpty)
                    GlassContainer(
                      padding: const EdgeInsets.all(16),
                      borderRadius: BorderRadius.circular(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'You said:',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: AppColors.darkOnSurfaceVariant),
                          ),
                          const SizedBox(height: 6),
                          Text(transcript,
                              style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ).animate().fadeIn(duration: 300.ms),

                  const SizedBox(height: 24),
                  Text('Voice', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 72,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _voices.length,
                      itemBuilder: (ctx, i) {
                        final voice = _voices[i];
                        final isSelected = selectedVoice == voice['id'];
                        return GestureDetector(
                          onTap: () => ref
                              .read(selectedVoiceProvider.notifier)
                              .state = voice['id']!,
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            width: 72,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.darkPrimary.withOpacity(0.15)
                                  : Theme.of(context)
                                      .colorScheme
                                      .surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.darkPrimary.withOpacity(0.5)
                                    : Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  voice['name']!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? AppColors.darkPrimary
                                        : null,
                                  ),
                                ),
                                Text(
                                  voice['desc']!,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 32),
                  if (history.isNotEmpty) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Recent',
                          style: Theme.of(context).textTheme.labelLarge),
                    ),
                    const SizedBox(height: 10),
                    ...history.take(5).map((s) => _HistoryTile(session: s)),
                  ],
                ],
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurface
                  : Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? AppColors.darkBorderFaint
                      : AppColors.lightBorder,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: _RecordButton(
                state: voiceState,
                onStart: _startRecording,
                onStop: _stopRecording,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

class _VoiceOrb extends StatelessWidget {
  final VoiceState state;
  final AnimationController pulseController;
  final int seconds;

  const _VoiceOrb({
    required this.state,
    required this.pulseController,
    required this.seconds,
  });

  @override
  Widget build(BuildContext context) {
    Color orbColor;
    String label;
    String emoji;
    switch (state) {
      case VoiceState.recording:
        orbColor = AppColors.darkTertiary;
        label =
            '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
        emoji = '🎙️';
        break;
      case VoiceState.processing:
        orbColor = AppColors.darkAccentYellow;
        label = 'Processing...';
        emoji = '⚙️';
        break;
      case VoiceState.speaking:
        orbColor = AppColors.darkAccentGreen;
        label = 'Speaking...';
        emoji = '🔊';
        break;
      case VoiceState.error:
        orbColor = AppColors.darkError;
        label = 'Error';
        emoji = '⚠️';
        break;
      default:
        orbColor = AppColors.darkPrimary;
        label = 'Tap to speak';
        emoji = '🎤';
    }

    return AnimatedBuilder(
      animation: pulseController,
      builder: (ctx, child) {
        final isActive =
            state == VoiceState.recording || state == VoiceState.speaking;
        final scale = isActive ? 1.0 + pulseController.value * 0.08 : 1.0;
        return Column(
          children: [
            Transform.scale(
              scale: scale,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: orbColor.withOpacity(
                          isActive ? 0.3 + pulseController.value * 0.2 : 0.15),
                      blurRadius: isActive ? 40 : 20,
                      spreadRadius: isActive ? 10 : 0,
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      orbColor.withOpacity(0.3),
                      orbColor.withOpacity(0.1),
                      Colors.transparent,
                    ]),
                  ),
                  child: Center(
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(colors: [
                          orbColor.withOpacity(0.9),
                          orbColor.withOpacity(0.6),
                        ]),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(emoji,
                            style: const TextStyle(fontSize: 32)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(label,
                  key: ValueKey(label),
                  style: Theme.of(ctx).textTheme.titleSmall),
            ),
          ],
        );
      },
    );
  }
}

class _RecordButton extends StatelessWidget {
  final VoiceState state;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const _RecordButton(
      {required this.state, required this.onStart, required this.onStop});

  @override
  Widget build(BuildContext context) {
    final isRecording = state == VoiceState.recording;
    final isProcessing =
        state == VoiceState.processing || state == VoiceState.speaking;

    return GestureDetector(
      onTap: isProcessing ? null : (isRecording ? onStop : onStart),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          gradient: isRecording
              ? LinearGradient(colors: [
                  AppColors.darkTertiary,
                  AppColors.darkTertiary.withOpacity(0.7),
                ])
              : isProcessing
                  ? null
                  : AppColors.primaryGradient,
          color: isProcessing ? AppColors.darkSurfaceVariant : null,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: isProcessing
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isRecording ? 'Stop Recording' : 'Tap to Record',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final VoiceSession session;
  const _HistoryTile({required this.session});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorderFaint : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('🎤', style: TextStyle(fontSize: 12)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(session.userText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      )),
            ),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            const Text('🤖', style: TextStyle(fontSize: 12)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(session.assistantText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          ]),
        ],
      ),
    );
  }
}
