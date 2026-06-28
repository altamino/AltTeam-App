import 'package:flutter/material.dart';
import '../theme/app_colors.dart';


class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.nickname,
    this.iconUrl,
    this.isVerified = false,
    this.size = 36,
    this.onTap,
  });

  final String nickname;
  final String? iconUrl;
  final bool isVerified;
  final double size;
  final VoidCallback? onTap;

  static const List<Color> _fallbackPalette = [
    Color(0xFF3D6BFF),
    Color(0xFF2FB6A3),
    Color(0xFFD6824A),
    Color(0xFF8A5CF6),
    Color(0xFFE5566B),
    Color(0xFF4FA8E0),
  ];

  Color _colorFor(String seed) {
    if (seed.isEmpty) return _fallbackPalette.first;
    final hash = seed.codeUnits.fold<int>(0, (acc, c) => acc + c);
    return _fallbackPalette[hash % _fallbackPalette.length];
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final hasIcon = iconUrl != null && iconUrl!.isNotEmpty;
    final initial = nickname.isNotEmpty ? nickname[0].toUpperCase() : '?';

    final core = ClipOval(
      child: hasIcon
          ? Image.network(
              iconUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallback(initial),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return _fallback(initial, loading: true);
              },
            )
          : _fallback(initial),
    );

    final stacked = Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: colors.glassBorder, width: 1.5),
          ),
          child: core,
        ),
        if (isVerified)
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(color: colors.surfaceElevated, shape: BoxShape.circle),
              child: Icon(Icons.verified, size: size * 0.34, color: colors.accentPrimary),
            ),
          ),
      ],
    );

    if (onTap == null) return stacked;
    return InkWell(borderRadius: BorderRadius.circular(size), onTap: onTap, child: stacked);
  }

  Widget _fallback(String initial, {bool loading = false}) {
    return Container(
      width: size,
      height: size,
      color: _colorFor(nickname),
      alignment: Alignment.center,
      child: loading
          ? SizedBox(
              width: size * 0.4,
              height: size * 0.4,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white.withOpacity(0.8)),
            )
          : Text(
              initial,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: size * 0.42),
            ),
    );
  }
}