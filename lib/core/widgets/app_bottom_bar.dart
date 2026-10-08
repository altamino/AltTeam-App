import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppBottomBarItem {
  const AppBottomBarItem({
    required this.label,
    required this.onTap,
    this.icon,
    this.avatarUrl,
    this.avatar = false,
    this.selected = false,
  }) : assert(icon != null || avatar, 'Нужна иконка или avatar: true');

  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  final bool avatar;
  final String? avatarUrl;
  final bool selected;
}

class AppBottomBar extends StatelessWidget {
  const AppBottomBar({super.key, required this.items});

  final List<AppBottomBarItem> items;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 66,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: colors.surfaceElevated.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: colors.glassBorder),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow,
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [for (final item in items) Expanded(child: _BarItem(item: item))],
            ),
          ),
        ),
      ),
    );
  }
}

class _BarItem extends StatelessWidget {
  const _BarItem({required this.item});
  final AppBottomBarItem item;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final color = item.selected ? colors.accentPrimary : colors.textMuted;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: item.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
        decoration: BoxDecoration(
          color: item.selected
              ? colors.accentPrimary.withValues(alpha: 0.16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (item.avatar)
              Container(
                padding: const EdgeInsets.all(1.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: item.selected ? colors.accentPrimary : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: CircleAvatar(
                  radius: 11,
                  backgroundColor: colors.accentPrimary.withValues(alpha: 0.2),
                  backgroundImage:
                      item.avatarUrl != null ? NetworkImage(item.avatarUrl!) : null,
                  child: item.avatarUrl == null
                      ? Icon(Icons.person, size: 14, color: colors.accentPrimary)
                      : null,
                ),
              )
            else
              Icon(item.icon, size: 24, color: color),
            const SizedBox(height: 3),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: item.selected ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}