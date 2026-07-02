import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/route_names.dart';
import '../../../../data/models/agent_model.dart';
import '../../../../shared/widgets/omni_app_bar.dart';
import '../../providers/agent_provider.dart';

class AgentsScreen extends ConsumerWidget {
  const AgentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allAgents = ref.watch(allAgentsProvider);
    final defaults = ref.watch(defaultAgentsProvider);
    final custom = ref.watch(agentsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground1 : null,
      appBar: OmniAppBar(
        title: 'AI Agents',
        actions: [
          IconButton(
            icon: const Icon(Icons.account_tree_rounded),
            onPressed: () => context.push(RouteNames.workflowBuilder),
            tooltip: 'Workflows',
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.push(RouteNames.agentBuilder),
            tooltip: 'New Agent',
          ),
        ],
      ),
      body: allAgents.isEmpty
          ? _Empty(onBuild: () => context.push(RouteNames.agentBuilder))
          : ListView(
              padding: const EdgeInsets.all(14),
              children: [
                if (defaults.isNotEmpty) ...[
                  _SectionHeader('Built-in Agents'),
                  ...defaults.asMap().entries.map((e) =>
                      _AgentCard(agent: e.value, index: e.key,
                        onRun: () => context.push(RouteNames.agentRun, extra: e.value))),
                ],
                if (custom.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _SectionHeader('My Agents'),
                  ...custom.asMap().entries.map((e) =>
                      _AgentCard(agent: e.value, index: e.key,
                        canDelete: true,
                        onDelete: () => ref.read(agentsProvider.notifier).delete(e.value.id),
                        onRun: () => context.push(RouteNames.agentRun, extra: e.value))),
                ],
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () => context.push(RouteNames.agentBuilder),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Build Custom Agent'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    side: BorderSide(color: AppColors.darkPrimary.withOpacity(0.4)),
                  ),
                ),
              ],
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(title, style: Theme.of(context).textTheme.labelLarge),
  );
}

class _AgentCard extends StatelessWidget {
  final AgentModel agent;
  final int index;
  final bool canDelete;
  final VoidCallback onRun;
  final VoidCallback? onDelete;

  const _AgentCard({
    required this.agent, required this.index, required this.onRun,
    this.canDelete = false, this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = Color(agent.color ?? 0xFF8B5CF6);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: Text(agent.iconEmoji ?? '🤖',
                      style: const TextStyle(fontSize: 22))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(agent.name, style: Theme.of(context).textTheme.titleSmall),
                    Text(agent.providerId.toUpperCase(),
                      style: TextStyle(fontSize: 10, color: color,
                          fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                  ]),
                ),
                if (canDelete && onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    onPressed: onDelete, padding: EdgeInsets.zero,
                    constraints: const BoxConstraints()),
              ],
            ),
            const SizedBox(height: 10),
            Text(agent.description, style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(height: 1.5)),
            const SizedBox(height: 12),
            Row(children: [
              if (agent.enableWebSearch) _Cap('Web Search', AppColors.darkSecondary),
              if (agent.enableCodeExecution) _Cap('Code Exec', AppColors.darkAccentGreen),
              if (agent.enableMemory) _Cap('Memory', AppColors.darkTertiary),
              const Spacer(),
              FilledButton.icon(
                onPressed: onRun,
                icon: const Icon(Icons.play_arrow_rounded, size: 16),
                label: const Text('Run'),
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  minimumSize: const Size(80, 34),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
              ),
            ]),
          ],
        ),
      ),
    ).animate(delay: Duration(milliseconds: index * 40)).fadeIn().slideY(begin: 0.1, end: 0);
  }
}

class _Cap extends StatelessWidget {
  final String label;
  final Color color;
  const _Cap(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(right: 6),
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Text(label, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
  );
}

class _Empty extends StatelessWidget {
  final VoidCallback onBuild;
  const _Empty({required this.onBuild});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 80, height: 80,
        decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(20)),
        child: const Center(child: Text('🤖', style: TextStyle(fontSize: 40))))
          .animate().scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
      const SizedBox(height: 20),
      Text('No Agents Yet', style: Theme.of(context).textTheme.headlineSmall).animate().fadeIn(delay: 150.ms),
      const SizedBox(height: 8),
      Text('Build AI agents that can use tools,\nsearch the web, and run code.',
        textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium)
          .animate().fadeIn(delay: 250.ms),
      const SizedBox(height: 28),
      FilledButton.icon(onPressed: onBuild, icon: const Icon(Icons.add_rounded), label: const Text('Build Agent'),
        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14)))
          .animate().fadeIn(delay: 350.ms),
    ]),
  );
}

extension _Str on String {
  String get toUpperCase => isEmpty ? this : this.toUpperCase();
}
