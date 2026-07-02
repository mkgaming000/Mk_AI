import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../shared/widgets/omni_app_bar.dart';
import '../../../settings/providers/settings_provider.dart';

class DocumentAIScreen extends ConsumerStatefulWidget {
  const DocumentAIScreen({super.key});
  @override ConsumerState<DocumentAIScreen> createState() => _DocumentAIScreenState();
}

class _DocumentAIScreenState extends ConsumerState<DocumentAIScreen> {
  String? _docContent, _docName, _analysis;
  bool _processing = false, _analyzing = false;
  final _questionCtrl = TextEditingController();
  String? _answer; bool _answering = false;

  @override void dispose() { _questionCtrl.dispose(); super.dispose(); }

  Future<void> _pick() async {
    setState(() { _processing = true; _analysis = null; _answer = null; });
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf','txt','md','csv','json'], withData: true);
      if (result == null) { setState(() => _processing = false); return; }
      final file = result.files.first;
      final content = file.extension?.toLowerCase() == 'pdf'
          ? '[PDF: ${file.name}] — Text extraction not available in this build.'
          : utf8.decode(file.bytes ?? Uint8List(0));
      setState(() { _docContent = content; _docName = file.name; _processing = false; });
    } catch (_) { setState(() => _processing = false); }
  }

  Future<void> _runOp(String op) async {
    if (_docContent == null) return;
    setState(() { _analyzing = true; _analysis = null; });
    final prompts = {'summarize': 'Summarize this document:', 'extract': 'Extract key points and facts:', 'analyze': 'Analyze this document comprehensively:' };
    final truncated = _docContent!.length > 12000 ? '${_docContent!.substring(0, 12000)}\n...[truncated]' : _docContent!;
    final buf = StringBuffer();
    try {
      final settings = ref.read(settingsProvider);
      await for (final chunk in ref.read(chatRepositoryProvider).streamResponse(
        providerId: settings.defaultProvider, modelId: settings.defaultModel, messages: [],
        systemPrompt: '${prompts[op] ?? 'Help with:'}\n\n---\n$truncated')) {
        buf.write(chunk); setState(() => _analysis = buf.toString());
      }
    } catch (e) { setState(() => _analysis = 'Error: $e'); }
    setState(() => _analyzing = false);
  }

  Future<void> _ask() async {
    final q = _questionCtrl.text.trim();
    if (q.isEmpty || _docContent == null) return;
    setState(() { _answering = true; _answer = null; });
    final truncated = _docContent!.length > 10000 ? '${_docContent!.substring(0, 10000)}\n...[truncated]' : _docContent!;
    final buf = StringBuffer();
    try {
      final settings = ref.read(settingsProvider);
      await for (final chunk in ref.read(chatRepositoryProvider).streamResponse(
        providerId: settings.defaultProvider, modelId: settings.defaultModel, messages: [],
        systemPrompt: 'Answer based only on the document below. Document:\n---\n$truncated\n\nQuestion: $q')) {
        buf.write(chunk); setState(() => _answer = buf.toString());
      }
    } catch (e) { setState(() => _answer = 'Error: $e'); }
    setState(() => _answering = false);
  }

  @override build(BuildContext context) => Scaffold(
    appBar: const OmniAppBar(title: 'Document AI'),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      _docContent == null
        ? GestureDetector(onTap: _processing ? null : _pick, child: Container(height: 140,
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceVariant, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.darkPrimary.withOpacity(0.3), style: BorderStyle.solid)),
            child: _processing ? const Center(child: CircularProgressIndicator()) : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: 52, height: 52, decoration: BoxDecoration(color: AppColors.darkPrimary.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.upload_file_rounded, color: AppColors.darkPrimary, size: 26)),
              const SizedBox(height: 8), const Text('Upload Document'), Text('PDF, TXT, MD, CSV, JSON', style: Theme.of(context).textTheme.bodySmall)])))
        : Container(padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.darkAccentGreen.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.darkAccentGreen.withOpacity(0.3))),
            child: Row(children: [const Icon(Icons.description_rounded, color: AppColors.darkAccentGreen), const SizedBox(width: 10),
              Expanded(child: Text(_docName!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
              IconButton(icon: const Icon(Icons.close_rounded, size: 18), onPressed: () => setState(() { _docContent = null; _docName = null; _analysis = null; _answer = null; }))])),
      if (_docContent != null) ...[
        const SizedBox(height: 14),
        Wrap(spacing: 8, runSpacing: 8, children: [
          ActionChip(label: const Text('📄 Summarize'), onPressed: _analyzing ? null : () => _runOp('summarize')),
          ActionChip(label: const Text('🔑 Key Points'), onPressed: _analyzing ? null : () => _runOp('extract')),
          ActionChip(label: const Text('🔬 Deep Analyze'), onPressed: _analyzing ? null : () => _runOp('analyze')),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextField(controller: _questionCtrl, decoration: const InputDecoration(hintText: 'Ask a question about this document...'), onSubmitted: (_) => _ask())),
          const SizedBox(width: 8),
          IconButton.filled(onPressed: _answering ? null : _ask, icon: _answering ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send_rounded, size: 18)),
        ]),
        if (_answer != null) Container(margin: const EdgeInsets.only(top: 12), padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.darkPrimary.withOpacity(0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.darkPrimary.withOpacity(0.15))),
          child: MarkdownBody(data: _answer!, selectable: true)).animate().fadeIn(),
        if (_analyzing) const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Center(child: CircularProgressIndicator()))
        else if (_analysis != null) Container(margin: const EdgeInsets.only(top: 12), padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceVariant, borderRadius: BorderRadius.circular(14)),
          child: MarkdownBody(data: _analysis!, selectable: true, styleSheet: MarkdownStyleSheet(p: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6)))).animate().fadeIn(),
      ],
    ]),
  );
}
