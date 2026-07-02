import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../features/settings/providers/settings_provider.dart';

class ModelSelectorChip extends ConsumerWidget {
  final String selectedProvider, selectedModel;
  final void Function(String provider, String model) onChanged;
  const ModelSelectorChip({super.key, required this.selectedProvider, required this.selectedModel, required this.onChanged});

  static const _providerModels = {
    'openai': ['gpt-4o', 'gpt-4o-mini', 'gpt-4-turbo', 'o1', 'o1-mini', 'o3-mini'],
    'anthropic': ['claude-opus-4-5', 'claude-sonnet-4-5', 'claude-haiku-4-5', 'claude-3-5-sonnet-20241022'],
    'google': ['gemini-2.0-flash-exp', 'gemini-1.5-pro', 'gemini-1.5-flash'],
    'xai': ['grok-3', 'grok-3-mini', 'grok-2-1212'],
    'deepseek': ['deepseek-chat', 'deepseek-reasoner'],
    'mistral': ['mistral-large-latest', 'codestral-latest', 'open-mistral-7b'],
    'openrouter': ['anthropic/claude-3.5-sonnet', 'meta-llama/llama-3.1-70b-instruct', 'google/gemini-pro-1.5'],
    'together': ['meta-llama/Llama-3-70b-chat-hf', 'meta-llama/Llama-3-8b-chat-hf'],
    'ollama': ['llama3.2:3b', 'llama3.1:8b', 'qwen2.5:7b', 'mistral:7b'],
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configured = ref.watch(configuredProvidersProvider);
    return GestureDetector(
      onTap: () => _showPicker(context, configured),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selectedProvider.toProviderColor().withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selectedProvider.toProviderColor().withOpacity(0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(selectedProvider.providerEmoji(), style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Flexible(child: Text(selectedModel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selectedProvider.toProviderColor()), maxLines: 1, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 4),
          Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: selectedProvider.toProviderColor()),
        ]),
      ),
    );
  }

  void _showPicker(BuildContext context, List<String> configured) {
    final providers = [..._providerModels.keys.where((p) => configured.contains(p) || p == 'openai')];
    String tempProvider = selectedProvider;
    String tempModel = selectedModel;
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, ss) => Container(
        height: MediaQuery.of(ctx).size.height * 0.6,
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Text('Select Model', style: Theme.of(ctx).textTheme.titleLarge), const Spacer(),
            FilledButton(onPressed: () { onChanged(tempProvider, tempModel); Navigator.pop(ctx); }, child: const Text('Done'))]),
          const SizedBox(height: 14),
          SizedBox(height: 44, child: ListView(scrollDirection: Axis.horizontal, children: providers.map((p) {
            final sel = tempProvider == p;
            return GestureDetector(onTap: () { ss(() { tempProvider = p; final models = _providerModels[p] ?? []; tempModel = models.isNotEmpty ? models.first : ''; }); },
              child: Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: sel ? p.toProviderColor().withOpacity(0.15) : Theme.of(ctx).colorScheme.surfaceVariant, borderRadius: BorderRadius.circular(10), border: Border.all(color: sel ? p.toProviderColor().withOpacity(0.4) : Colors.transparent)),
                child: Text('${p.providerEmoji()} $p', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? p.toProviderColor() : null))));
          }).toList())),
          const SizedBox(height: 14),
          Text('Models', style: Theme.of(ctx).textTheme.labelLarge),
          const SizedBox(height: 8),
          Expanded(child: ListView(children: (_providerModels[tempProvider] ?? []).map((m) {
            final sel = tempModel == m;
            return ListTile(title: Text(m, style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 13)), dense: true,
              trailing: sel ? Icon(Icons.check_rounded, color: tempProvider.toProviderColor(), size: 18) : null,
              selected: sel, selectedTileColor: tempProvider.toProviderColor().withOpacity(0.08),
              onTap: () => ss(() => tempModel = m));
          }).toList())),
        ]),
      )),
    );
  }
}
