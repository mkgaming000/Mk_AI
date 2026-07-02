import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/omni_app_bar.dart';

final _workspaceFilesProvider = FutureProvider.family<List<FileSystemEntity>, String?>((ref, path) async {
  final dir = path != null ? Directory(path) : await getApplicationDocumentsDirectory();
  if (!await dir.exists()) return [];
  try {
    return dir.listSync()..sort((a, b) {
      if (a is Directory && b is! Directory) return -1;
      if (a is! Directory && b is Directory) return 1;
      return p.basename(a.path).compareTo(p.basename(b.path));
    });
  } catch (_) { return []; }
});

class WorkspaceScreen extends ConsumerStatefulWidget {
  const WorkspaceScreen({super.key});
  @override ConsumerState<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends ConsumerState<WorkspaceScreen> {
  String? _path; final List<String> _hist = [];
  void _into(String path) => setState(() { if (_path != null) _hist.add(_path!); _path = path; });
  void _back() => setState(() => _path = _hist.isNotEmpty ? _hist.removeLast() : null);

  @override build(BuildContext context) {
    final files = ref.watch(_workspaceFilesProvider(_path));
    return Scaffold(
      appBar: OmniAppBar(
        title: _path != null ? p.basename(_path!) : 'Files',
        leading: (_path != null || _hist.isNotEmpty) ? IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: _back) : null,
        actions: [IconButton(icon: const Icon(Icons.create_new_folder_outlined), onPressed: () => _mkdir(context))]),
      body: files.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (entries) => entries.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.folder_open_rounded, size: 56, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.2)),
              const SizedBox(height: 12), const Text('Empty')]))
          : ListView.builder(padding: const EdgeInsets.all(8), itemCount: entries.length, itemBuilder: (_, i) {
              final e = entries[i]; final isDir = e is Directory; final name = p.basename(e.path);
              return ListTile(
                leading: Icon(isDir ? Icons.folder_rounded : _ico(name), color: isDir ? AppColors.darkAccentYellow : AppColors.darkSecondary),
                title: Text(name),
                subtitle: !isDir ? FutureBuilder<FileStat>(future: e.stat(), builder: (_, s) => s.hasData ? Text(s.data!.size.formattedFileSize) : const SizedBox()) : null,
                trailing: isDir ? const Icon(Icons.chevron_right_rounded, size: 18) : null,
                onTap: isDir ? () => _into(e.path) : null);
            })));
  }
  IconData _ico(String n) {
    final ext = p.extension(n).toLowerCase();
    if (['.png','.jpg','.jpeg','.gif','.webp'].contains(ext)) return Icons.image_rounded;
    if (ext == '.pdf') return Icons.picture_as_pdf_rounded;
    if (['.dart','.js','.ts','.py','.go','.rs'].contains(ext)) return Icons.code_rounded;
    if (['.mp3','.wav','.m4a'].contains(ext)) return Icons.audiotrack_rounded;
    return Icons.insert_drive_file_rounded;
  }
  Future<void> _mkdir(BuildContext context) async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('New Folder'),
      content: TextField(controller: ctrl, autofocus: true, decoration: const InputDecoration(hintText: 'Folder name')),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Create'))]));
    if (name != null && name.isNotEmpty) {
      final base = _path != null ? Directory(_path!) : await getApplicationDocumentsDirectory();
      await Directory(p.join(base.path, name)).create(recursive: true);
      ref.invalidate(_workspaceFilesProvider);
    }
  }
}
