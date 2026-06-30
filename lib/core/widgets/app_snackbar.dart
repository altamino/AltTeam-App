import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum SnackType { info, success, error }

class AppSnackbar {
  AppSnackbar._();

  static void show(
    BuildContext context,
    String message, {
    SnackType type = SnackType.info,
  }) {
    final colors = AppColors.of(context);
    final messenger = ScaffoldMessenger.of(context);

    messenger.hideCurrentSnackBar();

    final accent = switch (type) {
      SnackType.success => colors.accentPrimary,
      SnackType.error => colors.error,
      SnackType.info => colors.textSecondary,
    };

    final icon = switch (type) {
      SnackType.success => Icons.check_circle_rounded,
      SnackType.error => Icons.error_outline_rounded,
      SnackType.info => Icons.info_outline_rounded,
    };

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.glassFillStrong,
        elevation: 0,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: colors.glassBorder),
        ),
        content: Row(
          children: [
            Icon(icon, color: accent, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: colors.textPrimary, fontSize: 13.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}