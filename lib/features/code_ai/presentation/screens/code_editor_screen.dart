import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/route_names.dart';
import '../../../../shared/widgets/omni_app_bar.dart';
import '../../../settings/providers/settings_provider.dart';
import '../../../chat/providers/chat_provider.dart';
import '../../../../core/di/injection_container.dart';

class _EditorTab {
  String name, language, content;
  bool dirty;
  _EditorTab({required this.name, required this.language, required this.content, this.dirty = false});
}

final _tabsProvider = StateProvider<List<_EditorTab>>((ref) => [
  _EditorTab(name: 'main.dart', language: 'dart',
    content: 'void main() {\n  // OmniForge AI Code Editor\n  print("Hello, World!");\n}\n'),
]);
final _activeTabProvider = StateProvider<int>((ref) => 0);
final _outputProvider = StateProvider<String?>((ref) => null);

class CodeEditorScreen extends ConsumerStatefulWidget {
  const CodeEditorScreen({super.key});
  @override
  ConsumerState<CodeEditorScreen> createState() => _CodeEditorScreenState();
}

class _CodeEditorScreenState extends ConsumerState<CodeEditorScreen> {
  final _textCtrl = TextEditingController();
  bool _showOutput = false;
  bool _aiRunning = false;

  static const _langs = [
    {'id': 'dart', 'name': 'Dart', 'icon': '🎯'},
    {'id': 'python', 'name': 'Python', 'icon': '🐍'},
    {'id': 'javascript', 'name': 'JS', 'icon': '📜'},
    {'id': 'cpp', 'name': 'C++', 'icon': '⚙️'},
    {'id': 'rust', 'name': 'Rust', 'icon': '🦀'},
    {'id': 'kotlin', 'name': 'Kotlin', 'icon': '🤖'},
  ];

  @override
  void initState() {
    super.initState();
    final tabs = ref.read(_tabsProvider);
    if (tabs.isNotEmpty) {
      _textCtrl.text = tabs[0].content;
    }
    _textCtrl.addListener(() {
      final idx = ref.read(_activeTabProvider);
      final tabs = ref.read(_tabsProvider);
      if (idx < tabs.length) {
        tabs[idx].content = _textCtrl.text;
        tabs[idx].dirty = true;
      }
    });
  }

  @override
  void dispose() { _textCtrl.dispose(); super.dispose(); }

  void _switchTab(int i) {
    final tabs = ref.read(_tabsProvider);
    if (i >= tabs.length) return;
    ref.read(_activeTabProvider.notifier).state = i;
    _textCtrl.text = tabs[i].content;
  }

  void _addTab() {
    final tabs = [...ref.read(_tabsProvider), _EditorTab(name: 'new.dart', language: 'dart', content: '')];
    ref.read(_tabsProvider.notifier).state = tabs;
    _switchTab(tabs.length - 1);
  }

  Future<void> _run() async {
    final tabs = ref.read(_tabsProvider);
    final idx = ref.read(_activeTabProvider);
    if (idx >= tabs.length) return;
    setState(() { _showOutput = true; });
    ref.read(_outputProvider.notifier).state = 'Running ${tabs[idx].name}...\n';
    await Future.delayed(const Duration(milliseconds: 900));
    ref.read(_outputProvider.notifier).state =
        '[\$ ${tabs[idx].language}] Execution simulated.\n'
        'Connect a runtime via Settings → Terminal for live output.\n'
        '─────────────────────\nExit code: 0';
  }

  Future<void> _aiReview() async {
    final code = _textCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() { _aiRunning = true; _showOutput = true; });
    ref.read(_outputProvider.notifier).state = 'AI reviewing code...\n';
    final buf = StringBuffer();
    try {
      final settings = ref.read(settingsProvider);
      await for (final chunk in ref.read(chatRepositoryProvider).streamResponse(
        providerId: settings.defaultProvider,
        modelId: settings.defaultModel,
        messages: [],
        systemPrompt: 'Review this code for bugs, improvements, and best practices. Be concise:\n\n$code',
      )) {
        buf.write(chunk);
        ref.read(_outputProvider.notifier).state = buf.toString();
      }
    } catch (e) {
      ref.read(_outputProvider.notifier).state = 'AI review failed: $e';
    }
    setState(() => _aiRunning = false);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = ref.watch(_tabsProvider);
    final activeIdx = ref.watch(_activeTabProvider);
    final output = ref.watch(_outputProvider);
    final settings = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fs = settings.terminalFontSize;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: OmniAppBar(
        title: 'Code Editor',
        actions: [
          IconButton(icon: const Icon(Icons.folder_open_rounded, size: 20),
              onPressed: () => context.push(RouteNames.codeProjects), tooltip: 'Projects'),
          IconButton(icon: const Icon(Icons.smart_toy_outlined, size: 20),
              onPressed: _aiRunning ? null : _aiReview, tooltip: 'AI Review'),
          IconButton(icon: const Icon(Icons.play_arrow_rounded, color: AppColors.darkAccentGreen, size: 22),
              onPressed: _run, tooltip: 'Run'),
          IconButton(icon: const Icon(Icons.copy_rounded, size: 20),
              onPressed: () => Clipboard.setData(ClipboardData(text: _textCtrl.text)), tooltip: 'Copy'),
        ],
      ),
      body: Column(
        children: [
          // Tab bar
          Container(
            height: 40, color: const Color(0xFF161B22),
            child: Row(
              children: [
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: tabs.length,
                    itemBuilder: (_, i) {
                      final isActive = i == activeIdx;
                      return GestureDetector(
                        onTap: () => _switchTab(i),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: isActive ? const Color(0xFF0D1117) : Colors.transparent,
                            border: Border(bottom: BorderSide(
                              color: isActive ? AppColors.darkPrimary : Colors.transparent, width: 2))),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Text(tabs[i].name, style: TextStyle(
                              fontSize: 12, fontFamily: 'JetBrainsMono',
                              color: isActive ? Colors.white : Colors.white38)),
                            if (tabs[i].dirty) ...[const SizedBox(width: 4),
                              Container(width: 5, height: 5, decoration: const BoxDecoration(
                                color: AppColors.darkAccentOrange, shape: BoxShape.circle))],
                          ]),
                        ),
                      );
                    },
                  ),
                ),
                IconButton(icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white38),
                    padding: const EdgeInsets.all(6), onPressed: _addTab),
              ],
            ),
          ),

          // Editor
          Expanded(
            flex: _showOutput ? 6 : 10,
            child: Container(
              color: const Color(0xFF0D1117),
              child: TextField(
                controller: _textCtrl,
                maxLines: null,
                expands: true,
                style: TextStyle(
                  fontFamily: 'JetBrainsMono', fontSize: fs,
                  color: const Color(0xFFE6EDF3), height: 1.6,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(14),
                ),
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
              ),
            ),
          ),

          // Output panel
          if (_showOutput && output != null)
            Expanded(
              flex: 4,
              child: Container(
                color: const Color(0xFF161B22),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      color: const Color(0xFF1C2128),
                      child: Row(children: [
                        const Icon(Icons.terminal_rounded, size: 14, color: Colors.white38),
                        const SizedBox(width: 6),
                        const Text('Output', style: TextStyle(fontSize: 12, color: Colors.white38)),
                        const Spacer(),
                        if (_aiRunning) const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.darkPrimary)),
                        IconButton(icon: const Icon(Icons.close_rounded, size: 16, color: Colors.white38),
                            padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                            onPressed: () => setState(() => _showOutput = false)),
                      ]),
                    ),
                    Expanded(child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: SelectableText(output,
                        style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: fs,
                          color: const Color(0xFFCDD9E5), height: 1.6)),
                    )),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
