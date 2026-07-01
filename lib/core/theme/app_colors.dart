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
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.error,
    required this.errorBg,
    required this.errorBorder,
    required this.shadow,
  });

  final List<Color> bgGradient;
  final Color ambientGlow;
  final Color glassFill;
  final Color glassFillStrong;
  final Color glassBorder;
  final Color surfaceElevated;
  final Color accentPrimary;
  final Color accentPrimaryDim;
  final Color accentPrimaryGlow;
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
          BoxShadow(color: accentPrimaryGlow, blurRadius: 16, offset: const Offset(0, 4)),
        ],
      );
}


class AppColors {
  AppColors._();

  static const AppPalette dark = AppPalette(
      bgGradient: [Color(0xFF070A0E), Color(0xFF0D141A), Color(0xFF0A0E12)],
      ambientGlow: Color(0x1A00E676), // Мятное свечение
      glassFill: Color(0x0DFFFFFF),
      glassFillStrong: Color(0x14FFFFFF),
      glassBorder: Color(0x1AFFFFFF),
      surfaceElevated: Color(0xFF16222C),
      accentPrimary: Color(0xFF00BFA5), // Насыщенная бирюза/мята
      accentPrimaryDim: Color(0xFF00897B),
      accentPrimaryGlow: Color(0x5900BFA5),
      textPrimary: Color(0xFFF0F5F5),
      textSecondary: Color(0xA6FFFFFF),
      textMuted: Color(0x61FFFFFF),
      error: Color(0xFFFF5252),
      errorBg: Color(0x1FFF5252),
      errorBorder: Color(0x47FF5252),
      shadow: Color(0x33000000),
    );
  static const AppPalette light = AppPalette(
      bgGradient: [Color(0xFFF4F7F6), Color(0xFFEAF0EE), Color(0xFFE0E8E5)],
      ambientGlow: Color(0x1400BFA5),
      glassFill: Color(0xCCFFFFFF),
      glassFillStrong: Color(0xF2FFFFFF),
      glassBorder: Color(0x14000000),
      surfaceElevated: Color(0xFFFFFFFF),
      accentPrimary: Color(0xFF00796B),
      accentPrimaryDim: Color(0xFF004D40),
      accentPrimaryGlow: Color(0x4000796B),
      textPrimary: Color(0xFF0B1412),
      textSecondary: Color(0xFF42524E),
      textMuted: Color(0xFF80948F),
      error: Color(0xFFC62828),
      errorBg: Color(0x1AC62828),
      errorBorder: Color(0x40C62828),
      shadow: Color(0x14051410),
    );

  static AppPalette of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }
}