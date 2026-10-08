import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GlassDropdown<T> extends StatelessWidget {
  const GlassDropdown({
    super.key,
    required this.icon,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.enabled = true,
  });

  final IconData icon;
  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return PopupMenuButton<T>(
      enabled: enabled,
      initialValue: value,
      onSelected: onChanged,
      color: colors.surfaceElevated,
      elevation: 8,
      position: PopupMenuPosition.under,
      offset: const Offset(0, 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.glassBorder),
      ),
      itemBuilder: (context) => items.map((item) {
        final selected = item == value;
        return PopupMenuItem<T>(
          value: item,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  itemLabel(item),
                  style: TextStyle(
                    fontSize: 14,
                    color: selected ? colors.accentPrimary : colors.textPrimary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (selected)
                Icon(Icons.check_rounded, size: 16, color: colors.accentPrimary),
            ],
          ),
        );
      }).toList(),
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: colors.glassFillStrong,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.glassBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: colors.textMuted),
              const SizedBox(width: 6),
              Text(
                itemLabel(value),
                style: TextStyle(fontSize: 13, color: colors.textSecondary),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: colors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}