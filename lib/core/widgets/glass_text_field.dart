import 'package:flutter/material.dart';
import '../theme/app_colors.dart';


class GlassTextField extends StatefulWidget {
  const GlassTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.enabled = true,
    this.keyboardType,
    this.autofillHints,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isPassword;
  final bool enabled;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final VoidCallback? onSubmitted;

  @override
  State<GlassTextField> createState() => _GlassTextFieldState();
}

class _GlassTextFieldState extends State<GlassTextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.glassFillStrong,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.glassBorder),
      ),
      child: TextField(
        controller: widget.controller,
        obscureText: widget.isPassword && _obscure,
        enabled: widget.enabled,
        keyboardType: widget.keyboardType ??
            (widget.isPassword ? TextInputType.visiblePassword : null),
        autofillHints: widget.autofillHints,
        textInputAction: widget.textInputAction,
        onSubmitted: widget.onSubmitted == null ? null : (_) => widget.onSubmitted!(),
        cursorColor: colors.accentPrimary,
        style: TextStyle(color: colors.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: TextStyle(color: colors.textMuted, fontSize: 15),
          prefixIcon: Icon(widget.icon, size: 18, color: colors.textMuted),
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 18,
                    color: colors.textMuted,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
        ),
      ),
    );
  }
}
