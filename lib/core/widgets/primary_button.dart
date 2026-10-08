import 'package:flutter/material.dart';
import '../theme/app_colors.dart';


class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.height = 46,
    this.radius = 12,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final double height;
  final double radius;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final active = onPressed != null && !loading;

    return SizedBox(
      width: double.infinity,
      height: height,
      child: Opacity(
        opacity: (onPressed == null && !loading) ? 0.5 : 1,
        child: DecoratedBox(
          decoration: colors.primaryButton(radius: radius),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(radius),
              onTap: active ? onPressed : null,
              child: Center(
                child: loading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.onAccent,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, size: 18, color: colors.onAccent),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            label,
                            style: TextStyle(
                              color: colors.onAccent,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
