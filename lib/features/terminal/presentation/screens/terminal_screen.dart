import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/omni_app_bar.dart';
import '../../services/shell_session_service.dart';
import '../../../settings/providers/settings_provider.dart';

final _shellProvider = Provider.autoDispose((_) => ShellSessionService());

class _Line {
  final String text;
  final bool isInput;
  const _Line(this.text, {this.isInput = false});
}

class TerminalScreen extends ConsumerStatefulWidget {
  const TerminalScreen({super.key});

  @override
  ConsumerState<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends ConsumerState<TerminalScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focus = FocusNode();
  final List<_Line> _lines = [];
  late ShellSessionService _shell;

  static const _quickCmds = ['ls', 'pwd', 'cd ..', 'clear', 'git status', 'flutter doctor', 'help'];

  @override
  void initState() {
    super.initState();
    _shell = ref.read(_shellProvider);
    _lines.add(const _Line(
        'OmniForge AI Terminal v1.0\nDart 3.5 | Flutter 3.24\nType "help" for commands.\n'));
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _scrollBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
              duration: const Duration(milliseconds: 80), curve: Curves.easeOut);
        }
      });

  Future<void> _run([String? cmd]) async {
    final command = cmd ?? _inputCtrl.text;
    if (command.trim().isEmpty) return;
    setState(() {
      _lines.add(_Line('${_prompt()} $command', isInput: true));
      if (cmd == null) _inputCtrl.clear();
    });
    _scrollBottom();

    await for (final out in _shell.execute(command)) {
      if (!mounted) break;
      setState(() => _lines.add(_Line(out)));
      _scrollBottom();
    }
  }

  String _prompt() {
    final d = _shell.currentDirectory == _shell.environment['HOME']
        ? '~'
        : _shell.currentDirectory.split('/').last;
    return '${_shell.environment['USER']}@omniforge:$d\$';
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final fs = settings.terminalFontSize;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E14),
      appBar: OmniAppBar(
        title: 'Terminal',
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 20),
            onPressed: () => Clipboard.setData(ClipboardData(
                text: _lines.map((l) => l.text).join('\n'))),
            tooltip: 'Copy all',
          ),
          IconButton(
            icon: const Icon(Icons.clear_all_rounded, size: 20),
            onPressed: () => setState(() => _lines.clear()),
            tooltip: 'Clear',
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => _focus.requestFocus(),
        child: Column(
          children: [
            // Terminal output
            Expanded(
              child: Container(
                width: double.infinity,
                color: const Color(0xFF0A0E14),
                padding: const EdgeInsets.all(10),
                child: SingleChildScrollView(
                  controller: _scrollCtrl,
                  child: SelectionArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _lines
                          .map((l) => Text(
                                l.text,
                                style: TextStyle(
                                  fontFamily: 'JetBrainsMono',
                                  fontSize: fs,
                                  height: 1.55,
                                  color: l.isInput
                                      ? AppColors.darkAccentGreen
                                      : const Color(0xFFCDD9E5),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ),
            ),

            // Quick commands bar
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                itemCount: _quickCmds.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ActionChip(
                    label: Text(_quickCmds[i],
                        style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11)),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    backgroundColor: const Color(0xFF1C2333),
                    side: const BorderSide(color: Color(0xFF30363D)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onPressed: () => _run(_quickCmds[i]),
                  ),
                ),
              ),
            ),

            // Input bar
            Container(
              padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
              decoration: const BoxDecoration(
                color: Color(0xFF0F1420),
                border: Border(top: BorderSide(color: Color(0xFF21262D))),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Text(
                      '${_prompt()} ',
                      style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: fs,
                          color: AppColors.darkAccentGreen),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _inputCtrl,
                        focusNode: _focus,
                        autofocus: true,
                        style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: fs,
                            color: Colors.white),
                        cursorColor: AppColors.darkAccentGreen,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 4),
                        ),
                        textInputAction: TextInputAction.go,
                        onSubmitted: (_) => _run(),
                      ),
                    ),
                    GestureDetector(
                      onTap: _run,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.darkAccentGreen.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.keyboard_return_rounded,
                            color: AppColors.darkAccentGreen, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
