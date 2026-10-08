import 'package:flutter/material.dart';

class AppPalette {
  const AppPalette({
    required this.bgGradient,
    required this.ambientGlow,
    required this.glassFill,
    required this.glassFillStrong,
    required this.glassBorder,
    required this.surfaceElevated,
    required this.accentPrimary,
    required this.accentPrimaryDim,
    required this.accentPrimaryGlow,
    required this.onAccent,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.error,
    required this.errorBg,
    required this.errorBorder,
    required this.shadow,
  });


  factory AppPalette.fromSeed({
    required bool dark,
    required List<Color> background,
    required Color surface, 
    required Color accent,
    required Color accentDark,
    required Color text,
    required Color error,
    Color? glow, 
    Color onAccent = Colors.white, 
  }) {
    final base = dark ? Colors.white : Colors.black;
    return AppPalette(
      bgGradient: background,
      ambientGlow: (glow ?? accent).withValues(alpha: dark ? 0.16 : 0.10),
      glassFill: Colors.white.withValues(alpha: dark ? 0.06 : 0.80),
      glassFillStrong: Colors.white.withValues(alpha: dark ? 0.09 : 0.95),
      glassBorder: base.withValues(alpha: dark ? 0.12 : 0.08),
      surfaceElevated: surface,
      accentPrimary: accent,
      accentPrimaryDim: accentDark,
      accentPrimaryGlow: accent.withValues(alpha: dark ? 0.40 : 0.28),
      onAccent: onAccent,
      textPrimary: text,
      textSecondary: text.withValues(alpha: dark ? 0.68 : 0.75),
      textMuted: text.withValues(alpha: dark ? 0.42 : 0.52),
      error: error,
      errorBg: error.withValues(alpha: dark ? 0.12 : 0.10),
      errorBorder: error.withValues(alpha: dark ? 0.28 : 0.25),
      shadow: Colors.black.withValues(alpha: dark ? 0.25 : 0.08),
    );
  }

  final List<Color> bgGradient;
  final Color ambientGlow;
  final Color glassFill;
  final Color glassFillStrong;
  final Color glassBorder;
  final Color surfaceElevated;
  final Color accentPrimary;
  final Color accentPrimaryDim;
  final Color accentPrimaryGlow;
  final Color onAccent;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color error;
  final Color errorBg;
  final Color errorBorder;
  final Color shadow;

  BoxDecoration glassCard({double radius = 24}) => BoxDecoration(
        color: glassFill,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: glassBorder),
        boxShadow: [
          BoxShadow(color: shadow, blurRadius: 24, offset: const Offset(0, 8)),
        ],
      );

  BoxDecoration primaryButton({double radius = 12}) => BoxDecoration(
        color: accentPrimary,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: accentPrimaryDim),
        boxShadow: [
          BoxShadow(
            color: accentPrimaryGlow,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      );
}


class AppColors {
  AppColors._();

  static final AppPalette dark = AppPalette.fromSeed(
    dark: true,
    background: const [Color(0xFF080A24), Color(0xFF0E1140), Color(0xFF0A0C2E)],
    surface: const Color(0xFF171B52),
    accent: const Color.fromARGB(255, 86, 101, 237),
    accentDark: const Color.fromARGB(255, 18, 15, 61),
    text: const Color(0xFFF0F2FF),
    error: const Color(0xFFFF5252),
  );

  static final AppPalette light = AppPalette.fromSeed(
    dark: false,
    background: const [Color(0xFFF3F5FF), Color(0xFFE8ECFF), Color(0xFFDDE3FF)],
    surface: const Color(0xFFFFFFFF),
    accent: const Color(0xFF3B3BD6),
    accentDark: const Color(0xFF1A1470),
    text: const Color(0xFF0B0D2A),
    error: const Color(0xFFC62828),
  );

  static AppPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}
