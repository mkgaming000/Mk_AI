import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../data/datasources/remote/ollama_datasource.dart';
import '../../../../shared/widgets/omni_app_bar.dart';

final _availProvider = FutureProvider<bool>((ref) => ref.read(ollamaDatasourceProvider).isAvailable());
final _modelsProvider = FutureProvider<List<OllamaModel>>((ref) async {
  final ok = await ref.watch(_availProvider.future);
  if (!ok) return [];
  return ref.read(ollamaDatasourceProvider).listModels();
});

class LocalModelsScreen extends ConsumerStatefulWidget {
  const LocalModelsScreen({super.key});
  @override ConsumerState<LocalModelsScreen> createState() => _LocalModelsScreenState();
}

class _LocalModelsScreenState extends ConsumerState<LocalModelsScreen> {
  final _urlCtrl = TextEditingController();
  bool _pulling = false; double _progress = 0; String? _pullingModel;

  static const _popular = [
    {'name': 'llama3.2:3b', 'desc': 'Fast 3B — 2 GB'},
    {'name': 'llama3.1:8b', 'desc': 'Balanced 8B — 4.7 GB'},
    {'name': 'qwen2.5:7b', 'desc': 'Qwen 2.5 — 4.4 GB'},
    {'name': 'phi3.5:mini', 'desc': 'Microsoft Phi-3.5 — 2.2 GB'},
    {'name': 'mistral:7b', 'desc': 'Mistral 7B — 4.1 GB'},
    {'name': 'deepseek-r1:7b', 'desc': 'DeepSeek R1 — 4.7 GB'},
  ];

  @override void initState() {
    super.initState();
    _urlCtrl.text = ref.read(localStorageProvider).getStringOrDefault('ollama_base_url', 'http://10.0.2.2:11434');
  }
  @override void dispose() { _urlCtrl.dispose(); super.dispose(); }

  Future<void> _pull(String name) async {
    setState(() { _pulling = true; _progress = 0; _pullingModel = name; });
    try {
      await ref.read(ollamaDatasourceProvider).pullModel(name, onProgress: (p) => setState(() => _progress = p));
      ref.invalidate(_modelsProvider);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Download failed: $e')));
    } finally {
      if (mounted) setState(() { _pulling = false; _pullingModel = null; _progress = 0; });
    }
  }

  @override build(BuildContext context) {
    final avail = ref.watch(_availProvider);
    final models = ref.watch(_modelsProvider);
    return Scaffold(
      appBar: OmniAppBar(title: 'Local Models', actions: [
        IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: () { ref.invalidate(_availProvider); ref.invalidate(_modelsProvider); })]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text('Ollama Server', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: TextField(controller: _urlCtrl, decoration: const InputDecoration(hintText: 'http://10.0.2.2:11434', prefixIcon: Icon(Icons.link_rounded, size: 18)))),
          const SizedBox(width: 8),
          FilledButton(onPressed: () { ref.read(ollamaDatasourceProvider).setBaseUrl(_urlCtrl.text.trim()); ref.invalidate(_availProvider); ref.invalidate(_modelsProvider); }, child: const Text('Connect')),
        ]),
        const SizedBox(height: 6),
        Text('ADB tunnel: adb forward tcp:11434 tcp:11434', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 16),
        avail.when(loading: () => const LinearProgressIndicator(), error: (_, __) => _status(false), data: (ok) => _status(ok)),
        const SizedBox(height: 20),
        Text('Installed', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        models.when(loading: () => const Center(child: CircularProgressIndicator()), error: (e, _) => Text('$e'), data: (list) =>
          list.isEmpty ? Text('None yet', style: Theme.of(context).textTheme.bodySmall) :
          Column(children: list.map((m) => ListTile(leading: const Text('🦙', style: TextStyle(fontSize: 20)),
            title: Text(m.displayName, style: const TextStyle(fontFamily: 'JetBrainsMono', fontWeight: FontWeight.w600, fontSize: 13)),
            subtitle: Text('${m.tag} · ${m.formattedSize}'),
            trailing: IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 18), onPressed: () async { await ref.read(ollamaDatasourceProvider).deleteModel(m.name); ref.invalidate(_modelsProvider); }))).toList())),
        if (_pulling) ...[
          const SizedBox(height: 16),
          Text('Downloading $_pullingModel...', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: _progress, minHeight: 8, valueColor: const AlwaysStoppedAnimation(AppColors.darkPrimary))),
          Text('${(_progress * 100).toInt()}%', style: Theme.of(context).textTheme.bodySmall),
        ],
        const SizedBox(height: 24),
        Text('Download Models', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        ..._popular.map((m) => ListTile(leading: const Text('🦙', style: TextStyle(fontSize: 20)),
          title: Text(m['name']!, style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12, fontWeight: FontWeight.w600)),
          subtitle: Text(m['desc']!),
          trailing: _pullingModel == m['name'] ? CircularProgressIndicator(value: _progress) :
            TextButton(onPressed: _pulling ? null : () => _pull(m['name']!), child: const Text('Download')))),
      ]),
    );
  }

  Widget _status(bool ok) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(color: (ok ? AppColors.darkAccentGreen : AppColors.darkWarning).withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
    child: Row(children: [
      Icon(ok ? Icons.check_circle_rounded : Icons.warning_amber_rounded, color: ok ? AppColors.darkAccentGreen : AppColors.darkWarning, size: 16),
      const SizedBox(width: 8),
      Text(ok ? 'Ollama is running' : 'Ollama not detected — start it on your computer',
        style: TextStyle(color: ok ? AppColors.darkAccentGreen : AppColors.darkWarning, fontSize: 13)),
    ]));
}