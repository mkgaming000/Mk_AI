import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../data/models/agent_model.dart';
import '../../../../shared/widgets/omni_app_bar.dart';
import '../../services/agent_runner_service.dart';

final _agentRunnerProvider = Provider<AgentRunnerService>((ref) => AgentRunnerService(chatRepo: ref.read(chatRepositoryProvider), mcpClient: ref.read(mcpClientServiceProvider)));

enum _EventType { user, output, toolCall, toolResult, error }
class _Event { final _EventType type; final String content; bool isStreaming; _Event(this.type, this.content, {this.isStreaming = false}); }

class AgentRunScreen extends ConsumerStatefulWidget {
  final AgentModel agent;
  const AgentRunScreen({super.key, required this.agent});
  @override ConsumerState<AgentRunScreen> createState() => _AgentRunScreenState();
}

class _AgentRunScreenState extends ConsumerState<AgentRunScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<_Event> _events = [];
  bool _running = false;

  @override void dispose() { _inputCtrl.dispose(); _scrollCtrl.dispose(); super.dispose(); }

  void _scroll() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scrollCtrl.hasClients) _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 150), curve: Curves.easeOut);
  });

  Future<void> _run() async {
    final input = _inputCtrl.text.trim();
    if (input.isEmpty || _running) return;
    _inputCtrl.clear();
    setState(() { _running = true; _events.add(_Event(_EventType.user, input)); });

    final runner = ref.read(_agentRunnerProvider);
    final buf = StringBuffer();
    bool hasOutput = false;

    await for (final event in runner.run(agent: widget.agent, userInput: input)) {
      switch (event.type) {
        case AgentEventType.token:
          buf.write(event.content);
          if (!hasOutput) { hasOutput = true; setState(() => _events.add(_Event(_EventType.output, buf.toString(), isStreaming: true))); }
          else setState(() => _events.last = _Event(_EventType.output, buf.toString(), isStreaming: true));
          _scroll();
          break;
        case AgentEventType.toolCall:
          setState(() => _events.add(_Event(_EventType.toolCall, event.content)));
          _scroll(); break;
        case AgentEventType.toolResult:
          setState(() => _events.add(_Event(_EventType.toolResult, event.content)));
          buf.clear(); hasOutput = false; _scroll(); break;
        case AgentEventType.done:
          if (hasOutput) setState(() => _events.last = _Event(_EventType.output, buf.toString()));
          setState(() => _running = false); _scroll();
          NotificationService.instance.notifyAgentDone(widget.agent.name);
          break;
        case AgentEventType.error:
          setState(() { _events.add(_Event(_EventType.error, event.content)); _running = false; });
          _scroll(); break;
        default: break;
      }
    }
    if (_running) setState(() => _running = false);
  }

  @override build(BuildContext context) {
    final color = Color(widget.agent.color ?? 0xFF8B5CF6);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground1 : null,
      appBar: OmniAppBar(title: '${widget.agent.iconEmoji ?? "🤖"} ${widget.agent.name}', actions: [
        IconButton(icon: const Icon(Icons.delete_sweep_outlined), onPressed: () => setState(() => _events.clear()))]),
      body: Column(children: [
        Expanded(child: _events.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: 68, height: 68, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(18)), child: Center(child: Text(widget.agent.iconEmoji ?? '🤖', style: const TextStyle(fontSize: 34)))).animate().scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
              const SizedBox(height: 14), Text(widget.agent.name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6), Text(widget.agent.description, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center)]))
          : ListView.builder(controller: _scrollCtrl, padding: const EdgeInsets.all(14), itemCount: _events.length, itemBuilder: (_, i) {
              final e = _events[i];
              switch (e.type) {
                case _EventType.user: return Align(alignment: Alignment.centerRight, child: Container(margin: const EdgeInsets.only(bottom: 10, left: 40), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(14)), child: Text(e.content, style: const TextStyle(color: Colors.white, fontSize: 15)))).animate(delay: Duration(milliseconds: i * 20)).fadeIn();
                case _EventType.output: return Container(margin: const EdgeInsets.only(bottom: 10, right: 20), child: MarkdownBody(data: e.content, selectable: true));
                case _EventType.toolCall: return Container(margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.darkAccentYellow.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.darkAccentYellow.withOpacity(0.2))), child: Row(children: [const Icon(Icons.build_circle_outlined, size: 14, color: AppColors.darkAccentYellow), const SizedBox(width: 6), Expanded(child: Text(e.content, style: const TextStyle(fontSize: 12, color: AppColors.darkAccentYellow, fontStyle: FontStyle.italic)))])).animate().fadeIn();
                case _EventType.toolResult: return Container(margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.darkAccentGreen.withOpacity(0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.darkAccentGreen.withOpacity(0.2))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Row(children: [Icon(Icons.check_circle_outline_rounded, size: 12, color: AppColors.darkAccentGreen), SizedBox(width: 6), Text('Tool result', style: TextStyle(fontSize: 11, color: AppColors.darkAccentGreen, fontWeight: FontWeight.w600))]), const SizedBox(height: 4), Text(e.content.length > 200 ? '${e.content.substring(0, 200)}...' : e.content, style: const TextStyle(fontSize: 12, fontFamily: 'JetBrainsMono', height: 1.4))])).animate().fadeIn();
                case _EventType.error: return Container(margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Theme.of(context).colorScheme.errorContainer, borderRadius: BorderRadius.circular(10)), child: Text(e.content, style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)));
              }
            })),
        Container(padding: const EdgeInsets.fromLTRB(12, 8, 12, 12), color: isDark ? AppColors.darkSurface : Colors.white,
          child: SafeArea(top: false, child: Row(children: [
            Expanded(child: TextField(controller: _inputCtrl, maxLines: 3, minLines: 1, textInputAction: TextInputAction.send, onSubmitted: (_) => _run(), decoration: InputDecoration(hintText: 'Give ${widget.agent.name} a task...'))),
            const SizedBox(width: 8),
            GestureDetector(onTap: _run, child: AnimatedContainer(duration: const Duration(milliseconds: 200), width: 48, height: 48, decoration: BoxDecoration(gradient: _running ? null : AppColors.primaryGradient, color: _running ? AppColors.darkSurfaceVariant : null, borderRadius: BorderRadius.circular(14)),
              child: _running ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.darkPrimary))) : const Icon(Icons.send_rounded, color: Colors.white, size: 20))),
          ]))),
      ]),
    );
  }
}
