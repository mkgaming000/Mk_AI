import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/omni_app_bar.dart';

class UsageStatsScreen extends ConsumerWidget {
  const UsageStatsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracker = ref.read(costTrackerServiceProvider);
    final daily = tracker.getDailyUsage(7);
    final byProvider = tracker.getCostByProvider();
    return Scaffold(
      appBar: const OmniAppBar(title: 'Usage & Costs'),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Row(children: [
          Expanded(child: _StatCard(label: 'This Month', value: tracker.currentMonthSpent.formattedCost, icon: Icons.calendar_today_rounded, color: AppColors.darkPrimary)),
          const SizedBox(width: 12),
          Expanded(child: _StatCard(label: 'All Time', value: tracker.totalSpentAllTime.formattedCost, icon: Icons.savings_rounded, color: AppColors.darkAccentGreen)),
        ]),
        const SizedBox(height: 24),
        Text('Last 7 Days', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        SizedBox(height: 160, child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: daily.asMap().entries.map((e) {
            final d = e.value;
            final cost = (d['cost'] as double);
            final maxCost = daily.fold(0.0, (m, d) => (d['cost'] as double) > m ? (d['cost'] as double) : m);
            final h = maxCost > 0 ? (cost / maxCost) : 0.0;
            return Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
              if (cost > 0) Text(cost.formattedCost, style: const TextStyle(fontSize: 8)),
              const SizedBox(height: 2),
              AnimatedContainer(duration: const Duration(milliseconds: 500),
                height: (h * 100).clamp(4, 100).toDouble(),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 4),
              Text((d['date'] as DateTime).formattedShort, style: const TextStyle(fontSize: 9)),
            ]));
          }).toList(),
        )),
        const SizedBox(height: 24),
        Text('Cost by Provider', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        if (byProvider.isEmpty)
          Text('No usage yet', style: Theme.of(context).textTheme.bodySmall)
        else
          ...byProvider.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value))
            ..map((e) {
              final maxCost = byProvider.values.reduce((a, b) => a > b ? a : b);
              return Padding(padding: const EdgeInsets.only(bottom: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Text(e.key.capitalize, style: Theme.of(context).textTheme.bodyMedium), const Spacer(), Text(e.value.formattedCost, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))]),
                const SizedBox(height: 4),
                ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: maxCost > 0 ? e.value / maxCost : 0, minHeight: 6, backgroundColor: Theme.of(context).colorScheme.surfaceVariant, valueColor: const AlwaysStoppedAnimation(AppColors.darkPrimary))),
              ]));
            }).toList(),
      ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value; final IconData icon; final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});
  @override build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.2))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 20), const SizedBox(height: 10),
      Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: color)),
      const SizedBox(height: 2), Text(label, style: Theme.of(context).textTheme.bodySmall),
    ]));
}

extension _StringExt on String {
  String get capitalize => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}