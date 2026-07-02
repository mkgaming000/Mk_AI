import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../data/models/message_model.dart';
import '../../../../shared/widgets/omni_app_bar.dart';

class _CompareSlot {
  String provider;
  String model;
  String response;
  bool isStreaming;
  String? error;
  _CompareSlot({
    required this.provider,
    required this.model,
    this.response = '',
    this.isStreaming = false,
    this.error,
  });
}

class MultiModelCompareScreen extends ConsumerStatefulWidget {
  const MultiModelCompareScreen({super.key});
  @override
  ConsumerState<MultiModelCompareScreen> createState() => _MultiModelCompareScreenState();
}

class _MultiModelCompareScreenState extends ConsumerState<MultiModelCompareScreen> {
  final _promptCtrl = TextEditingController();
  final List<_CompareSlot> _slots = [
    _CompareSlot(provider: 'openai', model: 'gpt-4o'),
    _CompareSlot(provider: 'anthropic', model: 'claude-sonnet-4-5'),
  ];
  bool _running = false;

  @override
  void dispose() {
    _promptCtrl.dispose();
    super.dispose();
  }

  void _addSlot() {
    if (_slots.length >= 3) return;
    setState(() => _slots.add(_CompareSlot(provider: 'google', model: 'gemini-1.5-pro')));
  }

  void _removeSlot(int i) {
    if (_slots.length <= 2) return;
    setState(() => _slots.removeAt(i));
  }

  Future<void> _run() async {
    final prompt = _promptCtrl.text.trim();
    if (prompt.isEmpty || _running) return;

    setState(() {
      _running = true;
      for (final s in _slots) {
        s.response = '';
        s.isStreaming = true;
        s.error = null;
      }
    });

    final futures = _slots.map((slot) async {
      final buf = StringBuffer();
      try {
        final userMsg = MessageModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          conversationId: 'compare',
          role: MessageRole.user,
          content: prompt,
          createdAt: DateTime.now(),
        );
        await for (final chunk in ref.read(chatRepositoryProvider).streamResponse(
              providerId: slot.provider,
              modelId: slot.model,
              messages: [userMsg],
            )) {
          if (!mounted) return;
          buf.write(chunk);
          setState(() => slot.response = buf.toString());
        }
      } catch (e) {
        if (mounted) setState(() => slot.error = e.toString());
      } finally {
        if (mounted) setState(() => slot.isStreaming = false);
      }
    }).toList();

    await Future.wait(futures);
    if (mounted) setState(() => _running = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground1 : null,
      appBar: OmniAppBar(
        title: 'Compare Models',
        actions: [
          if (_slots.length < 3)
            IconButton(icon: const Icon(Icons.add_rounded), onPressed: _addSlot),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promptCtrl,
                    maxLines: 3,
                    minLines: 1,
                    decoration: const InputDecoration(hintText: 'Prompt to compare across models...'),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _run,
                  child: Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      gradient: _running ? null : AppColors.primaryGradient,
                      color: _running ? AppColors.darkSurfaceVariant : null,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: _running
                        ? const Center(child: SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.darkPrimary)))
                        : const Icon(Icons.compare_arrows_rounded, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: _slots.asMap().entries.map((entry) {
                final i = entry.key;
                final slot = entry.value;
                final color = slot.provider.toProviderColor();
                return Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(right: BorderSide(
                          color: isDark ? AppColors.darkBorderFaint : AppColors.lightBorder)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.06),
                            border: Border(bottom: BorderSide(color: color.withOpacity(0.2))),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Text(slot.provider.toUpperCase(),
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
                                const Spacer(),
                                if (_slots.length > 2)
                                  GestureDetector(onTap: () => _removeSlot(i),
                                      child: const Icon(Icons.close_rounded, size: 14)),
                              ]),
                              Text(slot.model, maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11, fontFamily: 'JetBrainsMono')),
                            ],
                          ),
                        ),
                        Expanded(
                          child: slot.error != null
                              ? Center(child: Padding(padding: const EdgeInsets.all(12),
                                  child: Text(slot.error!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12), textAlign: TextAlign.center)))
                              : slot.response.isEmpty && !slot.isStreaming
                                  ? const Center(child: Icon(Icons.chat_bubble_outline_rounded, size: 28, color: Colors.white12))
                                  : SingleChildScrollView(
                                      padding: const EdgeInsets.all(10),
                                      child: MarkdownBody(data: slot.response,
                                          styleSheet: MarkdownStyleSheet(p: const TextStyle(fontSize: 13, height: 1.5))),
                                    ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
