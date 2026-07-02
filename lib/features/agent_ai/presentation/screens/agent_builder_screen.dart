import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/omni_app_bar.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../settings/providers/settings_provider.dart';
import '../../providers/agent_provider.dart';

class AgentBuilderScreen extends ConsumerStatefulWidget {
  const AgentBuilderScreen({super.key});
  @override ConsumerState<AgentBuilderScreen> createState() => _AgentBuilderScreenState();
}

class _AgentBuilderScreenState extends ConsumerState<AgentBuilderScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _promptCtrl = TextEditingController();
  String _emoji = '🤖';
  bool _webSearch = false, _codeExec = false, _memory = false;
  double _temperature = 0.7;
  bool _saving = false;

  static const _emojis = ['🤖','🧠','🔬','💻','✍️','📊','🎯','⚡','🌐','🔍','📋','🎨'];

  @override void dispose() { _nameCtrl.dispose(); _descCtrl.dispose(); _promptCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    return Scaffold(
      appBar: const OmniAppBar(title: 'Build Agent'),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Center(child: Column(children: [
          GestureDetector(
            onTap: () => showDialog(context: context, builder: (ctx) => AlertDialog(
              title: const Text('Choose Icon'),
              content: Wrap(spacing: 8, runSpacing: 8, children: _emojis.map((e) => GestureDetector(
                onTap: () { setState(() => _emoji = e); Navigator.pop(ctx); },
                child: Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.darkPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Center(child: Text(e, style: const TextStyle(fontSize: 24)))),
              )).toList()))),
            child: Container(width: 72, height: 72, decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(18)), child: Center(child: Text(_emoji, style: const TextStyle(fontSize: 36))))),
          const SizedBox(height: 4),
          Text('Tap to change icon', style: Theme.of(context).textTheme.bodySmall),
        ])),
        const SizedBox(height: 20),
        TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Agent Name *', hintText: 'Research Assistant')),
        const SizedBox(height: 12),
        TextField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Description', hintText: 'What does this agent do?')),
        const SizedBox(height: 12),
        TextField(controller: _promptCtrl, maxLines: 6, decoration: const InputDecoration(labelText: 'System Prompt *', hintText: 'You are a helpful assistant specialized in...')),
        const SizedBox(height: 20),
        Text('Capabilities', style: Theme.of(context).textTheme.labelLarge),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Web Search'), subtitle: const Text('Search the internet for current info'), value: _webSearch, onChanged: (v) => setState(() => _webSearch = v)),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Code Execution'), subtitle: const Text('Write and run code'), value: _codeExec, onChanged: (v) => setState(() => _codeExec = v)),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Memory'), subtitle: const Text('Remember across sessions'), value: _memory, onChanged: (v) => setState(() => _memory = v)),
        const SizedBox(height: 16),
        Row(children: [
          Text('Temperature: ${_temperature.toStringAsFixed(1)}', style: Theme.of(context).textTheme.labelLarge),
          Expanded(child: Slider(value: _temperature, min: 0, max: 2, divisions: 20, onChanged: (v) => setState(() => _temperature = v))),
        ]),
        const SizedBox(height: 24),
        GradientButton(label: 'Create Agent', isLoading: _saving, width: double.infinity, height: 54,
          icon: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
          onPressed: () async {
            if (_nameCtrl.text.trim().isEmpty || _promptCtrl.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name and prompt are required')));
              return;
            }
            setState(() => _saving = true);
            await ref.read(agentsProvider.notifier).create(
              name: _nameCtrl.text.trim(), description: _descCtrl.text.trim(),
              systemPrompt: _promptCtrl.text.trim(), providerId: settings.defaultProvider,
              modelId: settings.defaultModel, iconEmoji: _emoji,
              enableWebSearch: _webSearch, enableCodeExecution: _codeExec,
              enableMemory: _memory, temperature: _temperature);
            setState(() => _saving = false);
            if (mounted) Navigator.pop(context);
          }),
        const SizedBox(height: 40),
      ]),
    );
  }
}
