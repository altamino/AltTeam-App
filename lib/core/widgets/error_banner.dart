import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ErrorBanner extends StatelessWidget {
  const ErrorBanner(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.errorBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.errorBorder),
      ),
      child: Text(message, style: TextStyle(fontSize: 13, color: colors.error)),
    );
  }
}
