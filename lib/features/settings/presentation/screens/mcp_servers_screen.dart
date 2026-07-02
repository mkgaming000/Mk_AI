import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/storage/database/hive_boxes.dart';
import '../../../../data/models/mcp_server_model.dart';
import '../../../../shared/widgets/omni_app_bar.dart';
import 'package:uuid/uuid.dart';

final _mcpProvider = StateNotifierProvider<_McpNotifier, List<McpServerModel>>(
  (ref) => _McpNotifier());

class _McpNotifier extends StateNotifier<List<McpServerModel>> {
  _McpNotifier() : super(HiveBoxes.mcpServers.values.toList());
  final _uuid = const Uuid();
  void refresh() => state = HiveBoxes.mcpServers.values.toList();
  Future<void> addServer({required String name, required String url, String? description}) async {
    final s = McpServerModel(id: _uuid.v4(), name: name, url: url, description: description, addedAt: DateTime.now());
    await HiveBoxes.mcpServers.put(s.id, s);
    refresh();
  }
  Future<void> toggleEnabled(String id) async {
    final s = HiveBoxes.mcpServers.get(id);
    if (s == null) return;
    s.isEnabled = !s.isEnabled;
    await HiveBoxes.mcpServers.put(id, s);
    refresh();
  }
  Future<void> remove(String id) async { await HiveBoxes.mcpServers.delete(id); refresh(); }
}

class McpServersScreen extends ConsumerWidget {
  const McpServersScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servers = ref.watch(_mcpProvider);
    return Scaffold(
      appBar: OmniAppBar(title: 'MCP Servers',
        actions: [IconButton(icon: const Icon(Icons.add_rounded), onPressed: () => _showAdd(context, ref))]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if (servers.isNotEmpty) ...[
          Text('Connected', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 10),
          ...servers.map((s) => _ServerTile(server: s,
            onToggle: () => ref.read(_mcpProvider.notifier).toggleEnabled(s.id),
            onDelete: () => ref.read(_mcpProvider.notifier).remove(s.id))),
          const SizedBox(height: 20),
        ],
        Container(padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.darkPrimary.withOpacity(0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.darkPrimary.withOpacity(0.15))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('What is MCP?', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            Text('Model Context Protocol lets AI agents use external tools — files, databases, APIs, and more.', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 10),
            FilledButton.icon(onPressed: () => _showAdd(context, ref), icon: const Icon(Icons.add_rounded, size: 16), label: const Text('Add MCP Server')),
          ])),
      ]),
    );
  }
  void _showAdd(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController(); final urlCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Add MCP Server'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
        const SizedBox(height: 10),
        TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'Server URL', hintText: 'https://mcp.example.com/sse')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () async {
          if (nameCtrl.text.isEmpty || urlCtrl.text.isEmpty) return;
          await ref.read(_mcpProvider.notifier).addServer(name: nameCtrl.text.trim(), url: urlCtrl.text.trim());
          if (ctx.mounted) Navigator.pop(ctx);
        }, child: const Text('Connect')),
      ],
    ));
  }
}

class _ServerTile extends StatelessWidget {
  final McpServerModel server; final VoidCallback onToggle; final VoidCallback onDelete;
  const _ServerTile({required this.server, required this.onToggle, required this.onDelete});
  @override build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceVariant, borderRadius: BorderRadius.circular(12)),
    child: Row(children: [
      const Icon(Icons.hub_rounded, color: AppColors.darkSecondary, size: 20), const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(server.name, style: Theme.of(context).textTheme.bodyLarge),
        Text(server.url, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
      ])),
      Switch(value: server.isEnabled, onChanged: (_) => onToggle()),
      IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 18), onPressed: onDelete),
    ]));
}