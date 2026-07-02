import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';

class OmniAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showLogo;
  final bool transparent;
  final VoidCallback? onTitleTap;
  final PreferredSizeWidget? bottom;

  const OmniAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.showLogo = false,
    this.transparent = false,
    this.onTitleTap,
    this.bottom,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      backgroundColor: transparent
          ? Colors.transparent
          : (isDark
              ? AppColors.darkSurface.withOpacity(0.95)
              : Colors.white.withOpacity(0.95)),
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: leading ??
          (Navigator.canPop(context)
              ? IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                )
              : null),
      title: showLogo
          ? const _OmniLogo()
          : titleWidget != null
              ? titleWidget
              : title != null
                  ? GestureDetector(
                      onTap: onTitleTap,
                      child: Text(title!,
                          style: Theme.of(context).textTheme.titleLarge),
                    )
                  : null,
      actions: actions,
      bottom: bottom,
      flexibleSpace: transparent
          ? null
          : Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? AppColors.darkBorderFaint
                        : AppColors.lightBorder,
                    width: 1,
                  ),
                ),
              ),
            ),
    );
  }
}

class _OmniLogo extends StatelessWidget {
  const _OmniLogo();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Text('⚡', style: TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(width: 10),
        ShaderMask(
          shaderCallback: (bounds) =>
              AppColors.primaryGradient.createShader(bounds),
          child: const Text('OmniForge',
              style: TextStyle(
                color: Colors.white, fontSize: 20,
                fontWeight: FontWeight.w700,
                fontFamily: 'SpaceGrotesk', letterSpacing: -0.5,
              )),
        ),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            gradient: AppColors.neonGlow,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text('AI',
              style: TextStyle(
                color: Colors.white, fontSize: 11,
                fontWeight: FontWeight.w700, letterSpacing: 0.5,
              )),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.1, end: 0);
  }
}
