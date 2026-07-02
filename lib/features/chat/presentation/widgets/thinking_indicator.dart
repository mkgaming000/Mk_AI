import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ThinkingIndicator extends StatefulWidget {
  final String? content;
  final bool isActive;
  const ThinkingIndicator({super.key, this.content, this.isActive = true});
  @override State<ThinkingIndicator> createState() => _ThinkingIndicatorState();
}

class _ThinkingIndicatorState extends State<ThinkingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  bool _expanded = false;
  @override void initState() { super.initState(); _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(); }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => setState(() => _expanded = !_expanded),
    child: Container(margin: const EdgeInsets.fromLTRB(12, 4, 48, 4), padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.darkPrimary.withOpacity(0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.darkPrimary.withOpacity(0.15))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (widget.isActive) AnimatedBuilder(animation: _ctrl, builder: (_, __) => Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.darkPrimary.withOpacity(0.5 + _ctrl.value * 0.5))))
          else const Icon(Icons.psychology_rounded, size: 14, color: AppColors.darkPrimary),
          const SizedBox(width: 8),
          Text(widget.isActive ? 'Thinking...' : 'Thought process', style: const TextStyle(fontSize: 12, color: AppColors.darkPrimary, fontWeight: FontWeight.w600)),
          const Spacer(),
          if (widget.content != null) Icon(_expanded ? Icons.expand_less : Icons.expand_more, size: 14, color: AppColors.darkPrimary),
        ]),
        if (_expanded && widget.content != null) ...[const SizedBox(height: 6), Text(widget.content!, style: const TextStyle(fontSize: 12, height: 1.5, fontStyle: FontStyle.italic, color: AppColors.darkOnSurfaceVariant))],
      ])));
}
