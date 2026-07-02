import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/omni_app_bar.dart';
import '../../../../shared/widgets/gradient_button.dart';

class WorkflowStep { String id, type, name; bool expanded;
  WorkflowStep({required this.id, required this.type, required this.name, this.expanded = false}); }

class WorkflowBuilderScreen extends ConsumerStatefulWidget {
  const WorkflowBuilderScreen({super.key});
  @override ConsumerState<WorkflowBuilderScreen> createState() => _WorkflowBuilderScreenState();
}

class _WorkflowBuilderScreenState extends ConsumerState<WorkflowBuilderScreen> {
  final _nameCtrl = TextEditingController();
  final List<WorkflowStep> _steps = [];
  bool _saving = false;

  static const _stepTypes = [
    {'type': 'agent', 'label': '🤖 Agent', 'color': 0xFF8B5CF6},
    {'type': 'prompt', 'label': '✏️ Prompt', 'color': 0xFF22D3EE},
    {'type': 'condition', 'label': '🔀 Condition', 'color': 0xFFFBBF24},
    {'type': 'output', 'label': '📤 Output', 'color': 0xFF34D399},
  ];

  @override void dispose() { _nameCtrl.dispose(); super.dispose(); }

  void _add(String type) {
    final def = _stepTypes.firstWhere((s) => s['type'] == type, orElse: () => _stepTypes.first);
    setState(() => _steps.add(WorkflowStep(id: '${DateTime.now().millisecondsSinceEpoch}', type: type, name: '${def['label']} Step', expanded: true)));
  }

  @override build(BuildContext context) {
    return Scaffold(
      appBar: const OmniAppBar(title: 'Workflow Builder'),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Workflow Name', hintText: 'Research & Summarize Pipeline')),
        const SizedBox(height: 20),
        Row(children: [Text('Steps', style: Theme.of(context).textTheme.titleMedium), const Spacer(), Text('${_steps.length} step${_steps.length == 1 ? "" : "s"}', style: Theme.of(context).textTheme.bodySmall)]),
        const SizedBox(height: 10),
        if (_steps.isEmpty) Container(height: 80, decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceVariant, borderRadius: BorderRadius.circular(12)), child: const Center(child: Text('Add steps below'))),
        ReorderableListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), onReorder: (o, n) { setState(() { if (n > o) n--; final s = _steps.removeAt(o); _steps.insert(n, s); }); },
          itemCount: _steps.length, itemBuilder: (_, i) {
            final step = _steps[i];
            final def = _stepTypes.firstWhere((s) => s['type'] == step.type, orElse: () => _stepTypes.first);
            final color = Color(def['color'] as int);
            return Container(key: ValueKey(step.id), margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceVariant, borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))),
              child: ListTile(leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)), child: Center(child: Text((def['label'] as String).split(' ').first))),
                title: Text(step.name), trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 20, height: 20, decoration: BoxDecoration(color: color, shape: BoxShape.circle), child: Center(child: Text('${i+1}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)))),
                  IconButton(icon: const Icon(Icons.close_rounded, size: 16), onPressed: () => setState(() => _steps.removeAt(i)), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                  const Icon(Icons.drag_handle_rounded, size: 18)])));
          }),
        const SizedBox(height: 16),
        Text('Add Step', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: _stepTypes.map((t) => GestureDetector(onTap: () => _add(t['type'] as String), child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceVariant, borderRadius: BorderRadius.circular(10), border: Border.all(color: Theme.of(context).colorScheme.outline)), child: Text(t['label'] as String, style: const TextStyle(fontSize: 13))))).toList()),
        const SizedBox(height: 24),
        GradientButton(label: _saving ? 'Saving...' : 'Save Workflow', isLoading: _saving, width: double.infinity, height: 52,
          onPressed: _steps.isEmpty ? null : () async {
            if (_nameCtrl.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add a workflow name'))); return; }
            setState(() => _saving = true);
            await Future.delayed(const Duration(milliseconds: 600));
            setState(() => _saving = false);
            if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Workflow saved'))); Navigator.pop(context); }
          }),
        const SizedBox(height: 32),
      ]),
    );
  }
}
