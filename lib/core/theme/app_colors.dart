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
    bgGradient: [Color(0xFF0B0E14), Color(0xFF121826), Color(0xFF0E1420)],
    ambientGlow: Color(0x1A3D6BFF),
    glassFill: Color(0x0DFFFFFF),
    glassFillStrong: Color(0x14FFFFFF),
    glassBorder: Color(0x1AFFFFFF),
    surfaceElevated: Color(0xFF1A2233),
    accentPrimary: Color(0xFF3D6BFF),
    accentPrimaryDim: Color(0xFF2B4ED6),
    accentPrimaryGlow: Color(0x593D6BFF),
    textPrimary: Color(0xFFF4F6FA),
    textSecondary: Color(0xA6FFFFFF),
    textMuted: Color(0x61FFFFFF),
    error: Color(0xFFFF6B6B),
    errorBg: Color(0x1FFF6B6B),
    errorBorder: Color(0x47FF6B6B),
    shadow: Color(0x33000000),
  );

  static const AppPalette light = AppPalette(
    bgGradient: [Color(0xFFF6F7FB), Color(0xFFEEF1F8), Color(0xFFE7ECF6)],
    ambientGlow: Color(0x142F5FE0),
    glassFill: Color(0xCCFFFFFF),
    glassFillStrong: Color(0xF2FFFFFF),
    glassBorder: Color(0x14000000),
    surfaceElevated: Color(0xFFFFFFFF),
    accentPrimary: Color(0xFF2F5FE0),
    accentPrimaryDim: Color(0xFF24439C),
    accentPrimaryGlow: Color(0x402F5FE0),
    textPrimary: Color(0xFF1A1F2B),
    textSecondary: Color(0xFF4B5468),
    textMuted: Color(0xFF8B93A3),
    error: Color(0xFFD64545),
    errorBg: Color(0x1AD64545),
    errorBorder: Color(0x40D64545),
    shadow: Color(0x14000000),
  );

  static AppPalette of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }
}