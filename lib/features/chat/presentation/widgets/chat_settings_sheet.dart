import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// A bottom sheet that lets the user actually change temperature,
/// max tokens, and system prompt for the current chat session.
/// Values are applied live via [onApply] which the caller wires to
/// the ChatNotifier's real setters.
class ChatSettingsSheet extends StatefulWidget {
  final double temperature;
  final int maxTokens;
  final String? systemPrompt;
  final void Function({
    required double temperature,
    required int maxTokens,
    required String? systemPrompt,
  }) onApply;

  const ChatSettingsSheet({
    super.key,
    required this.temperature,
    required this.maxTokens,
    this.systemPrompt,
    required this.onApply,
  });

  @override
  State<ChatSettingsSheet> createState() => _ChatSettingsSheetState();
}

class _ChatSettingsSheetState extends State<ChatSettingsSheet> {
  late double _temperature;
  late int _maxTokens;
  late TextEditingController _systemCtrl;

  static const _presets = [
    {'label': '🎯 Precise', 'temp': 0.1, 'tokens': 2048},
    {'label': '⚖️ Balanced', 'temp': 0.7, 'tokens': 4096},
    {'label': '🎨 Creative', 'temp': 1.2, 'tokens': 8192},
  ];

  @override
  void initState() {
    super.initState();
    _temperature = widget.temperature;
    _maxTokens = widget.maxTokens;
    _systemCtrl = TextEditingController(text: widget.systemPrompt ?? '');
  }

  @override
  void dispose() {
    _systemCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (ctx, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.darkBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('Chat Settings', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),

            Text('System Prompt', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _systemCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'You are a helpful assistant. Be concise and accurate.',
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Text('Temperature', style: Theme.of(context).textTheme.labelLarge),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.darkPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _temperature.toStringAsFixed(1),
                    style: const TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkPrimary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            Slider(
              value: _temperature,
              min: 0,
              max: 2,
              divisions: 20,
              label: _temperature.toStringAsFixed(1),
              onChanged: (v) => setState(() => _temperature = v),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Precise', style: Theme.of(context).textTheme.bodySmall),
                Text('Balanced', style: Theme.of(context).textTheme.bodySmall),
                Text('Creative', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Text('Max Response Tokens', style: Theme.of(context).textTheme.labelLarge),
                const Spacer(),
                Text(
                  '$_maxTokens',
                  style: const TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            Slider(
              value: _maxTokens.toDouble().clamp(256, 16384),
              min: 256,
              max: 16384,
              divisions: 63,
              label: '$_maxTokens',
              onChanged: (v) => setState(() => _maxTokens = v.round()),
            ),
            const SizedBox(height: 20),

            Text('Presets', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presets.map((p) {
                return GestureDetector(
                  onTap: () => setState(() {
                    _temperature = p['temp'] as double;
                    _maxTokens = p['tokens'] as int;
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Theme.of(context).colorScheme.outline),
                    ),
                    child: Text(p['label'] as String,
                        style: Theme.of(context).textTheme.bodySmall),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            FilledButton(
              onPressed: () {
                widget.onApply(
                  temperature: _temperature,
                  maxTokens: _maxTokens,
                  systemPrompt: _systemCtrl.text.trim().isEmpty
                      ? null
                      : _systemCtrl.text.trim(),
                );
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
              child: const Text('Apply Settings'),
            ),
          ],
        ),
      ),
    );
  }
}
