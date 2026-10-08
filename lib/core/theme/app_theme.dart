import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(AppColors.light, Brightness.light);
  static ThemeData get dark => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppPalette p, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: p.accentPrimary,
      brightness: brightness,
    ).copyWith(
      primary: p.accentPrimary,
      onPrimary: p.onAccent,
      surface: p.surfaceElevated,
      onSurface: p.textPrimary,
      error: p.error,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.bgGradient.first,
      canvasColor: p.surfaceElevated,
      dividerColor: p.glassBorder,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.accentPrimary,
        selectionColor: p.accentPrimary.withValues(alpha: 0.30),
        selectionHandleColor: p.accentPrimary,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.accentPrimary),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.surfaceElevated,
        contentTextStyle: TextStyle(color: p.textPrimary),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
