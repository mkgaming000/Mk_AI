import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/omni_app_bar.dart';
import '../../../../shared/widgets/gradient_button.dart';

enum MusicGenStatus { idle, generating, playing, paused, error }

class MusicGenState {
  final MusicGenStatus status;
  final String prompt;
  final String selectedProvider;
  final String? genre;
  final String? mood;
  final int durationSeconds;
  final bool instrumental;
  final String? resultUrl;
  final String? lyrics;
  final String? error;

  const MusicGenState({
    this.status = MusicGenStatus.idle,
    this.prompt = '',
    this.selectedProvider = 'suno',
    this.genre,
    this.mood,
    this.durationSeconds = 30,
    this.instrumental = false,
    this.resultUrl,
    this.lyrics,
    this.error,
  });

  MusicGenState copyWith({
    MusicGenStatus? status,
    String? prompt,
    String? selectedProvider,
    String? genre,
    String? mood,
    int? durationSeconds,
    bool? instrumental,
    String? resultUrl,
    String? lyrics,
    String? error,
  }) =>
      MusicGenState(
        status: status ?? this.status,
        prompt: prompt ?? this.prompt,
        selectedProvider: selectedProvider ?? this.selectedProvider,
        genre: genre ?? this.genre,
        mood: mood ?? this.mood,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        instrumental: instrumental ?? this.instrumental,
        resultUrl: resultUrl,
        lyrics: lyrics,
        error: error,
      );

  bool get isGenerating => status == MusicGenStatus.generating;
}

final musicGenProvider =
    StateNotifierProvider<MusicGenNotifier, MusicGenState>(
        (ref) => MusicGenNotifier());

class MusicGenNotifier extends StateNotifier<MusicGenState> {
  MusicGenNotifier() : super(const MusicGenState());

  void setPrompt(String p) => state = state.copyWith(prompt: p);
  void setProvider(String p) =>
      state = state.copyWith(selectedProvider: p);
  void setGenre(String? g) => state = state.copyWith(genre: g);
  void setMood(String? m) => state = state.copyWith(mood: m);
  void setDuration(int s) => state = state.copyWith(durationSeconds: s);
  void toggleInstrumental() =>
      state = state.copyWith(instrumental: !state.instrumental);

  Future<void> generate() async {
    if (state.prompt.trim().isEmpty) return;
    state = state.copyWith(status: MusicGenStatus.generating, error: null);
    try {
      // Real API calls to Suno/Udio require their API tokens.
      // Connect via Settings → API Keys.
      await Future.delayed(const Duration(seconds: 2));
      state = state.copyWith(
        status: MusicGenStatus.idle,
        resultUrl: null,
        lyrics: state.instrumental
            ? null
            : 'Connect your Suno or Udio API key in\n'
                'Settings → API Keys to generate real music.',
      );
    } catch (e) {
      state = state.copyWith(status: MusicGenStatus.error, error: e.toString());
    }
  }
}

class MusicGenScreen extends ConsumerStatefulWidget {
  const MusicGenScreen({super.key});

  @override
  ConsumerState<MusicGenScreen> createState() => _MusicGenScreenState();
}

class _MusicGenScreenState extends ConsumerState<MusicGenScreen> {
  final _promptController = TextEditingController();
  final _player = AudioPlayer();
  bool _isPlaying = false;

  static const _providers = [
    {'id': 'suno', 'name': 'Suno', 'icon': '🎵'},
    {'id': 'udio', 'name': 'Udio', 'icon': '🎶'},
  ];

  static const _genres = [
    'Pop', 'Rock', 'Jazz', 'Classical', 'Hip-Hop',
    'Electronic', 'Ambient', 'Folk', 'R&B', 'Country',
  ];

  static const _moods = [
    'Happy', 'Sad', 'Energetic', 'Calm', 'Mysterious',
    'Romantic', 'Epic', 'Chill',
  ];

  @override
  void dispose() {
    _promptController.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback(String url) async {
    if (_isPlaying) {
      await _player.pause();
      setState(() => _isPlaying = false);
    } else {
      try {
        await _player.setUrl(url);
        await _player.play();
        setState(() => _isPlaying = true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Playback error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(musicGenProvider);
    final notifier = ref.read(musicGenProvider.notifier);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground1 : null,
      appBar: const OmniAppBar(title: 'Music Studio'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Provider selector
          Row(
            children: _providers.map((p) {
              final isSelected = state.selectedProvider == p['id'];
              return Expanded(
                child: GestureDetector(
                  onTap: () => notifier.setProvider(p['id']!),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.darkPrimary.withOpacity(0.15)
                          : Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.darkPrimary.withOpacity(0.5)
                            : Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${p['icon']} ${p['name']}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isSelected ? AppColors.darkPrimary : null,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Audio visualizer card
          _AudioVisualizerCard(
            state: state,
            isPlaying: _isPlaying,
            onPlayPause: state.resultUrl != null
                ? () => _togglePlayback(state.resultUrl!)
                : null,
          ),
          const SizedBox(height: 20),

          // Prompt
          Text('Describe your music',
              style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: Theme.of(context).colorScheme.outline),
            ),
            child: TextField(
              controller: _promptController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText:
                    'An uplifting acoustic guitar melody with soft piano, '
                    'feels like a morning walk in a forest...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(14),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Genre chips
          Text('Genre', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _genres.map((g) {
              final isSelected = state.genre == g;
              return GestureDetector(
                onTap: () => notifier.setGenre(isSelected ? null : g),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.darkPrimary.withOpacity(0.15)
                        : Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.darkPrimary.withOpacity(0.4)
                          : Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  child: Text(g,
                      style: TextStyle(
                          fontSize: 13,
                          color: isSelected ? AppColors.darkPrimary : null)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Mood chips
          Text('Mood', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _moods.map((m) {
              final isSelected = state.mood == m;
              return GestureDetector(
                onTap: () => notifier.setMood(isSelected ? null : m),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.darkSecondary.withOpacity(0.15)
                        : Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.darkSecondary.withOpacity(0.4)
                          : Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  child: Text(m,
                      style: TextStyle(
                          fontSize: 13,
                          color: isSelected
                              ? AppColors.darkSecondary
                              : null)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Instrumental Only'),
            subtitle: const Text('No vocals'),
            value: state.instrumental,
            onChanged: (_) => notifier.toggleInstrumental(),
          ),

          // API key info banner
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: AppColors.darkPrimary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.darkPrimary.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppColors.darkPrimary, size: 16),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Suno & Udio API keys required. Add in Settings → API Keys.',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.darkPrimary),
                  ),
                ),
              ],
            ),
          ),

          if (state.lyrics != null) ...[
            const SizedBox(height: 16),
            Text('Lyrics', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(state.lyrics!,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(height: 1.8, fontStyle: FontStyle.italic)),
            ).animate().fadeIn(duration: 300.ms),
          ],

          if (state.status == MusicGenStatus.error) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(state.error ?? 'Unknown error',
                  style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onErrorContainer)),
            ),
          ],

          const SizedBox(height: 24),
          GradientButton(
            label: state.isGenerating ? 'Composing...' : 'Generate Music',
            isLoading: state.isGenerating,
            width: double.infinity,
            height: 54,
            icon: state.isGenerating
                ? null
                : const Icon(Icons.music_note_rounded,
                    color: Colors.white, size: 18),
            onPressed: state.isGenerating
                ? null
                : () {
                    notifier.setPrompt(_promptController.text);
                    notifier.generate();
                  },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _AudioVisualizerCard extends StatefulWidget {
  final MusicGenState state;
  final bool isPlaying;
  final VoidCallback? onPlayPause;

  const _AudioVisualizerCard({
    required this.state,
    required this.isPlaying,
    this.onPlayPause,
  });

  @override
  State<_AudioVisualizerCard> createState() => _AudioVisualizerCardState();
}

class _AudioVisualizerCardState extends State<_AudioVisualizerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void didUpdateWidget(_AudioVisualizerCard old) {
    super.didUpdateWidget(old);
    if (widget.isPlaying && !_animController.isAnimating) {
      _animController.repeat(reverse: true);
    } else if (!widget.isPlaying) {
      _animController.stop();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasResult = widget.state.resultUrl != null;

    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppColors.darkPrimary.withOpacity(0.2),
          AppColors.darkSecondary.withOpacity(0.1),
        ]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkPrimary.withOpacity(0.2)),
      ),
      child: widget.state.isGenerating
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text('Composing music...',
                      style: TextStyle(color: Colors.white70)),
                ],
              ),
            )
          : Row(
              children: [
                const SizedBox(width: 16),
                IconButton(
                  onPressed: hasResult ? widget.onPlayPause : null,
                  icon: Icon(
                    widget.isPlaying
                        ? Icons.pause_circle_filled_rounded
                        : Icons.play_circle_filled_rounded,
                    size: 44,
                    color: hasResult
                        ? AppColors.darkPrimary
                        : Colors.white24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: hasResult && widget.isPlaying
                      ? AnimatedBuilder(
                          animation: _animController,
                          builder: (ctx, _) => CustomPaint(
                            painter: _WaveformPainter(
                              progress: _animController.value,
                              color: AppColors.darkPrimary,
                            ),
                            size: const Size(double.infinity, 40),
                          ),
                        )
                      : Center(
                          child: Text(
                            hasResult
                                ? widget.state.prompt
                                : 'No music yet',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 12),
                          ),
                        ),
                ),
                const SizedBox(width: 16),
              ],
            ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final double progress;
  final Color color;
  _WaveformPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.7)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const barCount = 28;
    final maxHeight = size.height;

    for (int i = 0; i < barCount; i++) {
      final phase = i / barCount + progress;
      final h = (math.sin(phase * math.pi * 4) * 0.5 + 0.5) * maxHeight;
      final x = i * (size.width / barCount) + 2;
      canvas.drawLine(
        Offset(x, (size.height - h) / 2),
        Offset(x, (size.height + h) / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) => old.progress != progress;
}
