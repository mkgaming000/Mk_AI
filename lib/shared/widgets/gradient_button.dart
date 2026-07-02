import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class GradientButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Gradient? gradient;
  final Widget? icon;
  final bool isLoading;
  final double? width;
  final double height;
  final BorderRadius? borderRadius;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? padding;

  const GradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.gradient,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height = 52,
    this.borderRadius,
    this.textStyle,
    this.padding,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final gradient = widget.gradient ?? AppColors.primaryGradient;
    final disabled = widget.onPressed == null && !widget.isLoading;
    final br = widget.borderRadius ?? BorderRadius.circular(14);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        if (!widget.isLoading) widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: widget.width,
        height: widget.height,
        transform: _pressed ? (Matrix4.identity()..scale(0.97)) : Matrix4.identity(),
        decoration: BoxDecoration(
          gradient: disabled
              ? LinearGradient(
                  colors: (gradient as LinearGradient)
                      .colors
                      .map((c) => c.withOpacity(0.4))
                      .toList(),
                )
              : gradient,
          borderRadius: br,
          boxShadow: disabled || _pressed
              ? []
              : [
                  BoxShadow(
                    color: AppColors.darkPrimary.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: br,
            onTap: disabled || widget.isLoading ? null : widget.onPressed,
            splashColor: Colors.white.withOpacity(0.1),
            child: Container(
              padding: widget.padding ??
                  const EdgeInsets.symmetric(horizontal: 24),
              alignment: Alignment.center,
              child: widget.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null) ...[
                          widget.icon!,
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.label,
                          style: widget.textStyle ??
                              Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
