import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final double blur;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? shadows;
  final Gradient? gradient;
  final VoidCallback? onTap;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.blur = 10,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.shadows,
    this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final br = borderRadius ?? BorderRadius.circular(16);
    final bg = backgroundColor ??
        (isDark ? AppColors.glassLight : Colors.white.withOpacity(0.6));
    final border = borderColor ??
        (isDark ? AppColors.glassBorder : AppColors.lightBorder);

    Widget content = ClipRRect(
      borderRadius: br,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: br,
            gradient: gradient,
            border: Border.all(color: border, width: borderWidth),
            boxShadow: shadows ?? [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (margin != null) content = Padding(padding: margin!, child: content);
    if (onTap != null) content = GestureDetector(onTap: onTap, child: content);
    return content;
  }
}
