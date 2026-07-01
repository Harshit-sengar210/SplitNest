import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final double blur;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final List<BoxShadow>? shadows;
  final Border? border;
  final Color? baseColor;
  final double opacity;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.blur = 0.0, // Deprecated but kept for API compatibility
    this.borderRadius = 12.0, // Updated to 12px
    this.padding = const EdgeInsets.all(24.0),
    this.margin,
    this.shadows, // Deprecated but kept for API compatibility
    this.border,
    this.baseColor,
    this.opacity = 1.0, // Solid background
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: baseColor ?? context.colors.card,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ??
            Border.all(
              color: context.colors.accentBrown,
              width: 1.0,
            ),
      ),
      child: child,
    );
  }
}
