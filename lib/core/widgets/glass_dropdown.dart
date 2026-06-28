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
  final String Function(T item) itemLabel;
  final ValueChanged<T>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return PopupMenuButton<T>(
      enabled: enabled,
      initialValue: value,
      color: colors.surfaceElevated,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.glassBorder),
      ),
      onSelected: onChanged,
      itemBuilder: (context) => items.map((item) {
        final selected = item == value;
        return PopupMenuItem<T>(
          value: item,
          height: 40,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  itemLabel(item),
                  style: TextStyle(
                    color: selected ? colors.accentPrimary : colors.textPrimary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 13,
                  ),
                ),
              ),
              if (selected) Icon(Icons.check, size: 15, color: colors.accentPrimary),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colors.glassFill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.glassBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: colors.textMuted),
            const SizedBox(width: 6),
            Text(
              itemLabel(value),
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
            const SizedBox(width: 4),
            Icon(Icons.expand_more, size: 14, color: colors.textMuted),
          ],
        ),
      ),
    );
  }
}