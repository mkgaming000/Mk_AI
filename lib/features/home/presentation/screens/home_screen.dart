import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/route_names.dart';

class HomeScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const HomeScreen({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _BottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: (i) => navigationShell.goBranch(i,
            initialLocation: i == navigationShell.currentIndex),
      ),
      floatingActionButton: navigationShell.currentIndex == 0
          ? _QuickFab() : null,
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.currentIndex, required this.onTap});

  static const _items = [
    (icon: Icons.chat_bubble_outline_rounded, active: Icons.chat_bubble_rounded, label: 'Chat'),
    (icon: Icons.auto_awesome_outlined, active: Icons.auto_awesome_rounded, label: 'Create'),
    (icon: Icons.code_outlined, active: Icons.code_rounded, label: 'Code'),
    (icon: Icons.smart_toy_outlined, active: Icons.smart_toy_rounded, label: 'Agents'),
    (icon: Icons.settings_outlined, active: Icons.settings_rounded, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface.withOpacity(0.95) : Colors.white.withOpacity(0.95),
        border: Border(top: BorderSide(color: isDark ? AppColors.darkBorderFaint : AppColors.lightBorder)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: _items.asMap().entries.map((e) {
              final i = e.key;
              final item = e.value;
              final isActive = currentIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.darkPrimary.withOpacity(0.12) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ShaderMask(
                          shaderCallback: (b) => isActive
                              ? AppColors.primaryGradient.createShader(b)
                              : LinearGradient(colors: [
                                  isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant,
                                  isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant,
                                ]).createShader(b),
                          child: Icon(isActive ? item.active : item.icon,
                              color: Colors.white, size: 24),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(item.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                          color: isActive ? AppColors.darkPrimary
                              : (isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant),
                        )),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _QuickFab extends StatefulWidget {
  @override
  State<_QuickFab> createState() => _QuickFabState();
}

class _QuickFabState extends State<_QuickFab> with SingleTickerProviderStateMixin {
  bool _open = false;
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _toggle() {
    setState(() => _open = !_open);
    _open ? _ctrl.forward() : _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_open) ...[
          _MiniAction(emoji: '🖼️', label: 'Image', onTap: () { _toggle(); context.push(RouteNames.imageGen); }),
          const SizedBox(height: 8),
          _MiniAction(emoji: '🎙️', label: 'Voice', onTap: () { _toggle(); context.push(RouteNames.voiceAI); }),
          const SizedBox(height: 8),
          _MiniAction(emoji: '🔍', label: 'Search', onTap: () { _toggle(); context.push(RouteNames.search); }),
          const SizedBox(height: 8),
          _MiniAction(emoji: '📄', label: 'Docs', onTap: () { _toggle(); context.push(RouteNames.documentAI); }),
          const SizedBox(height: 8),
        ],
        FloatingActionButton(
          onPressed: _toggle,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: AppColors.darkPrimary.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 4))],
            ),
            child: AnimatedRotation(
              turns: _open ? 0.125 : 0,
              duration: const Duration(milliseconds: 250),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniAction extends StatelessWidget {
  final String emoji, label;
  final VoidCallback onTap;
  const _MiniAction({required this.emoji, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: Text(label, style: Theme.of(context).textTheme.labelMedium),
          ),
          const SizedBox(width: 8),
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
          ),
        ],
      ),
    );
  }
}
