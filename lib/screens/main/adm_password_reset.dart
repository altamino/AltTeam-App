import 'package:flutter/material.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/admin_header.dart';

class AdminPasswordResetScreen extends StatefulWidget {
  const AdminPasswordResetScreen({super.key});

  @override
  State<AdminPasswordResetScreen> createState() => _AdminPasswordResetScreenState();
}

class _AdminPasswordResetScreenState extends State<AdminPasswordResetScreen> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() => _sending = true);
    // TODO: call backend to generate and email a new password to this address.
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _sending = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.t('admin.password_reset.not_ready'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors.bgGradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              AdminHeader(title: AppLocalizations.t('admin.password_reset.title')),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.t('admin.password_reset.label'),
                      style: TextStyle(color: colors.textMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: colors.glassFill,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.glassBorder),
                      ),
                      child: TextField(
                        controller: _controller,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(color: colors.textPrimary, fontSize: 13.5),
                        decoration: InputDecoration(
                          hintText: AppLocalizations.t('admin.password_reset.hint'),
                          hintStyle: TextStyle(color: colors.textMuted, fontSize: 13.5),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: _sending ? null : _send,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.accentPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _sending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(AppLocalizations.t('admin.password_reset.send')),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}