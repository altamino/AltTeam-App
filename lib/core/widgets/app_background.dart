import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({
    super.key,
    required this.child,
    this.imageAsset,
    this.imageOpacity = 0.35,
    this.glow = true,
  });

  final Widget child;
  final String? imageAsset;
  final double imageOpacity;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors.bgGradient,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (glow) ...[
            Positioned(top: -100, left: -60, child: _Glow(320, colors.ambientGlow)),
            Positioned(bottom: -140, right: -80, child: _Glow(360, colors.ambientGlow)),
          ],
          if (imageAsset != null && isDark)
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: imageOpacity,
                  child: Image.asset(
                    imageAsset!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          child,
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow(this.size, this.color);
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, Colors.transparent]),
        ),
      ),
    );
  }
}
