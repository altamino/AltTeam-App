import 'package:flutter/material.dart';

import '../deps.dart';

class TabScroll extends StatefulWidget {
  const TabScroll({super.key, required this.children});
  final List<Widget> children;

  @override
  State<TabScroll> createState() => _TabScrollState();
}

class _TabScrollState extends State<TabScroll>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        24 + MediaQuery.of(context).padding.bottom,
      ),
      children: widget.children,
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.icon,
    this.trailing,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.glassFill,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (icon != null) ...[
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: colors.accentPrimary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(icon, size: 18, color: colors.accentPrimary),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title!,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            subtitle!,
                            style: TextStyle(
                                color: colors.textMuted, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            SizedBox(height: trailing != null ? 4 : 14),
          ],
          child,
        ],
      ),
    );
  }
}

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Text(
      text,
      style: TextStyle(
        color: colors.textMuted,
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.controller,
    required this.hint,
    this.label,
    this.validator,
    this.minLines,
    this.maxLines = 1,
    this.prefixText,
    this.prefixIcon,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String hint;
  final String? label;
  final String? Function(String?)? validator;
  final int? minLines;
  final int maxLines;
  final String? prefixText;
  final IconData? prefixIcon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final radius = BorderRadius.circular(16);

    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: c, width: w),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          FieldLabel(label!),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: controller,
          validator: validator,
          minLines: minLines,
          maxLines: maxLines,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          textInputAction: textInputAction,
          cursorColor: colors.accentPrimary,
          style: TextStyle(color: colors.textPrimary, fontSize: 14.5),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: colors.textMuted, fontSize: 14),
            prefixText: prefixText,
            prefixStyle: TextStyle(
                color: colors.accentPrimary,
                fontSize: 14.5,
                fontWeight: FontWeight.w600),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: colors.textMuted, size: 21)
                : null,
            filled: true,
            fillColor: colors.glassFillStrong,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: border(colors.glassBorder),
            enabledBorder: border(colors.glassBorder),
            focusedBorder: border(colors.accentPrimary, 1.6),
            errorBorder: border(colors.error),
            focusedErrorBorder: border(colors.error, 1.6),
          ),
        ),
      ],
    );
  }
}

class SwitchRow extends StatelessWidget {
  const SwitchRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.icon,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 2, 6, 2),
      decoration: BoxDecoration(
        color: colors.glassFillStrong,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.glassBorder),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: colors.textMuted),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: colors.textPrimary, fontSize: 14),
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: colors.accentPrimary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class RoundAvatar extends StatelessWidget {
  const RoundAvatar({
    super.key,
    required this.url,
    required this.radius,
    this.ringColor,
  });

  final dynamic url;
  final double radius;
  final Color? ringColor;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final has = url is String && (url as String).startsWith('http');

    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: colors.glassFillStrong,
      backgroundImage: has ? NetworkImage(url as String) : null,
      child: has ? null : Icon(Icons.person_rounded, color: colors.textMuted),
    );

    if (ringColor == null) return avatar;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ringColor!, width: 2),
      ),
      child: avatar,
    );
  }
}

class InfoPill extends StatelessWidget {
  const InfoPill({
    super.key,
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: colors.glassFill,
              shape: BoxShape.circle,
              border: Border.all(color: colors.glassBorder),
            ),
            child: Icon(icon, size: 32, color: colors.textMuted),
          ),
          const SizedBox(height: 14),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

Future<bool?> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) {
  final colors = AppColors.of(context);
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: colors.glassFillStrong,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(title,
          style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold)),
      content: Text(message,
          style: TextStyle(color: colors.textMuted, fontSize: 14)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(AppLocalizations.t('common.cancel'),
              style: TextStyle(color: colors.textMuted)),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(confirmLabel,
              style: TextStyle(
                  color: destructive ? colors.error : colors.accentPrimary,
                  fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}