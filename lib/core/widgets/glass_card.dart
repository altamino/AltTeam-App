import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';


class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.radius = 20,
    this.padding = const EdgeInsets.all(24),
    this.width,
    this.blur = 24,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double blur;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          padding: padding,
          decoration: colors.glassCard(radius: radius),
          child: child,
        ),
      ),
    );
  }
}
