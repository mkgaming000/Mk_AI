import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/storage/database/hive_boxes.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../data/models/code_project_model.dart';
import '../../../../shared/widgets/omni_app_bar.dart';

final _codeProjectsProvider =
    StateNotifierProvider<_ProjectsNotifier, List<CodeProjectModel>>(
        (ref) => _ProjectsNotifier());

class _ProjectsNotifier extends StateNotifier<List<CodeProjectModel>> {
  _ProjectsNotifier()
      : super(HiveBoxes.codeProjects.values.toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)));

  final _uuid = const Uuid();

  void _reload() => state = HiveBoxes.codeProjects.values.toList()
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  Future<void> create(String name, String lang) async {
    final p = CodeProjectModel(
      id: _uuid.v4(),
      name: name,
      workspaceId: 'default',
      language: lang,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await HiveBoxes.codeProjects.put(p.id, p);
    _reload();
  }

  Future<void> delete(String id) async {
    await HiveBoxes.codeProjects.delete(id);
    _reload();
  }
}

class CodeProjectsScreen extends ConsumerWidget {
  const CodeProjectsScreen({super.key});

  static const _langs = [
    {'id': 'dart', 'name': 'Dart/Flutter', 'icon': '🎯'},
    {'id': 'python', 'name': 'Python', 'icon': '🐍'},
    {'id': 'javascript', 'name': 'JavaScript', 'icon': '📜'},
    {'id': 'typescript', 'name': 'TypeScript', 'icon': '💙'},
    {'id': 'cpp', 'name': 'C++', 'icon': '⚙️'},
    {'id': 'rust', 'name': 'Rust', 'icon': '🦀'},
    {'id': 'go', 'name': 'Go', 'icon': '🐹'},
    {'id': 'kotlin', 'name': 'Kotlin', 'icon': '🤖'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(_codeProjectsProvider);
    return Scaffold(
      appBar: OmniAppBar(
        title: 'Projects',
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showNew(context, ref),
          ),
        ],
      ),
      body: projects.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.folder_open_rounded,
                      size: 56, color: Colors.white24),
                  const SizedBox(height: 16),
                  const Text('No projects yet'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _showNew(context, ref),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('New Project'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: projects.length,
              itemBuilder: (_, i) {
                final p = projects[i];
                final lang = _langs.firstWhere(
                    (l) => l['id'] == p.language,
                    orElse: () => _langs.first);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.darkPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(lang['icon']!,
                            style: const TextStyle(fontSize: 22)),
                      ),
                    ),
                    title: Text(p.name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                        '${lang['name']} · ${p.updatedAt.timeAgo}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 18),
                      onPressed: () => ref
                          .read(_codeProjectsProvider.notifier)
                          .delete(p.id),
                    ),
                    onTap: () => Navigator.pop(context),
                  ),
                );
              },
            ),
    );
  }

  void _showNew(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    String lang = 'dart';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          title: const Text('New Project'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Project name'),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _langs.map((l) => GestureDetector(
                  onTap: () => ss(() => lang = l['id']!),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: lang == l['id']
                          ? AppColors.darkPrimary.withOpacity(0.15)
                          : Theme.of(ctx).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: lang == l['id']
                            ? AppColors.darkPrimary
                            : Colors.transparent,
                      ),
                    ),
                    child: Text(
                      '${l['icon']} ${l['name']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: lang == l['id'] ? AppColors.darkPrimary : null,
                      ),
                    ),
                  ),
                )).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (ctrl.text.trim().isEmpty) return;
                await ref
                    .read(_codeProjectsProvider.notifier)
                    .create(ctrl.text.trim(), lang);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}
