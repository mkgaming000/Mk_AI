class ShellSessionService {
  String currentDirectory = '/home/omniforge';
  final Map<String, String> environment = {
    'HOME': '/home/omniforge', 'USER': 'omniforge',
    'SHELL': '/bin/bash', 'TERM': 'xterm-256color',
  };
  final List<String> history = [];
  final Map<String, String> _files = {
    '/home/omniforge/README.md': 'Welcome to OmniForge AI Terminal\nType "help" for commands.\n',
  };
  final Map<String, List<String>> _dirs = {
    '/home/omniforge': ['README.md', 'projects'],
    '/home/omniforge/projects': [],
  };

  Stream<String> execute(String command) async* {
    final trimmed = command.trim();
    if (trimmed.isEmpty) return;
    history.add(trimmed);
    final parts = _tok(trimmed);
    final cmd = parts.first;
    final args = parts.skip(1).toList();

    switch (cmd) {
      case 'help':
        yield 'OmniForge Terminal\n\nNavigation: ls, cd, pwd, mkdir\nFiles: cat, echo\nDev: flutter, dart, python, node, git\nSystem: whoami, date, env, uname, clear, history, exit';
        break;
      case 'pwd':
        yield currentDirectory;
        break;
      case 'ls':
        final entries = _dirs[currentDirectory];
        if (entries != null && entries.isNotEmpty) yield entries.join('  ');
        break;
      case 'cd':
        if (args.isEmpty) {
          currentDirectory = environment['HOME']!;
        } else if (args.first == '..') {
          final parts2 = currentDirectory.split('/')..removeLast();
          currentDirectory = parts2.join('/');
          if (currentDirectory.isEmpty) currentDirectory = '/';
        } else {
          final np = args.first.startsWith('/') ? args.first : '$currentDirectory/${args.first}';
          if (_dirs.containsKey(np)) {
            currentDirectory = np;
          } else {
            yield 'cd: ${args.first}: No such file or directory';
          }
        }
        break;
      case 'mkdir':
        if (args.isEmpty) {
          yield 'mkdir: missing operand';
        } else {
          final np = '$currentDirectory/${args.first}';
          _dirs[np] = [];
          _dirs[currentDirectory]?.add(args.first);
        }
        break;
      case 'cat':
        if (args.isEmpty) {
          yield 'cat: missing operand';
        } else {
          final path = args.first.startsWith('/') ? args.first : '$currentDirectory/${args.first}';
          yield _files[path] ?? 'cat: ${args.first}: No such file or directory';
        }
        break;
      case 'echo':
        yield args.join(' ');
        break;
      case 'clear':
        yield '\x1b[2J\x1b[H';
        break;
      case 'whoami':
        yield environment['USER']!;
        break;
      case 'date':
        yield DateTime.now().toString();
        break;
      case 'uname':
        yield 'Linux omniforge-android aarch64';
        break;
      case 'env':
        for (final e in environment.entries) {
          yield '${e.key}=${e.value}';
        }
        break;
      case 'history':
        for (int i = 0; i < history.length; i++) {
          yield '${i + 1}  ${history[i]}';
        }
        break;
      case 'flutter':
        if (args.isEmpty) {
          yield 'Flutter SDK — usage: flutter <command>';
        } else if (args.first == '--version') {
          yield 'Flutter 3.24.0 • channel stable\nDart 3.5.0';
        } else if (args.first == 'doctor') {
          yield '[✓] Flutter (stable)\n[✓] Android toolchain\n[✓] Connected device';
        } else if (args.first == 'pub') {
          yield 'Resolving dependencies...\nGot dependencies!';
        } else {
          yield 'flutter ${args.join(' ')}: executed';
        }
        break;
      case 'dart':
        if (args.contains('--version')) {
          yield 'Dart SDK version: 3.5.0';
        } else {
          yield 'dart ${args.join(' ')}: executed';
        }
        break;
      case 'python':
      case 'python3':
        if (args.contains('--version') || args.contains('-v')) {
          yield 'Python 3.12.1';
        } else {
          yield 'Python sandbox (simulation)';
        }
        break;
      case 'node':
        if (args.contains('--version') || args.contains('-v')) {
          yield 'v20.11.0';
        } else {
          yield 'Node sandbox (simulation)';
        }
        break;
      case 'git':
        if (args.isEmpty) {
          yield 'usage: git <command>';
        } else {
          switch (args.first) {
            case 'status': yield 'On branch main\nnothing to commit, working tree clean'; break;
            case 'init': yield 'Initialized empty Git repository'; break;
            case '--version': yield 'git version 2.43.0'; break;
            default: yield 'git ${args.join(' ')}: executed';
          }
        }
        break;
      case 'npm':
      case 'pip':
        yield '$cmd ${args.join(' ')}\nSimulated package operation.';
        break;
      case 'exit':
        yield 'logout';
        break;
      default:
        yield 'bash: $cmd: command not found';
    }
  }

  List<String> _tok(String input) {
    final r = RegExp(r'"[^"]*"|\S+');
    return r.allMatches(input).map((m) => m.group(0)!.replaceAll('"', '')).toList();
  }
}
