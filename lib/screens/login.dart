import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api/constants.dart';
import '../core/api/objects/args/roles.dart';
import '../core/api/repositories/auth.dart';
import '../core/l10n/app_localizations.dart';
import '../core/storage.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/app_background.dart';
import '../core/widgets/error_banner.dart';
import '../core/widgets/glass_card.dart';
import '../core/widgets/glass_dropdown.dart';
import '../core/widgets/glass_text_field.dart';
import '../core/widgets/primary_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.onSetTheme,
    required this.onSetLocale,
  });

  final void Function(ThemeMode) onSetTheme;
  final void Function(Locale) onSetLocale;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authRepo = AuthRepository();

  late ThemeMode _themeMode;
  late String _lang;
  List<LocaleInfo> _locales = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _themeMode = Storage.themeMode;
    _lang = Storage.locale;
    AppLocalizations.availableLocales().then((l) {
      if (mounted) setState(() => _locales = l);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _login() async {
    if (_loading) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = AppLocalizations.t('auth.login.fill_all_fields'));
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _authRepo.login(email, password);
      final role = res['userProfile']?['role'] as int? ?? 0;
      if (!RoleTypes.isStaffRole(role) && adminsOnly) {
        await _authRepo.logout();
        if (mounted) {
          setState(() => _error = AppLocalizations.t('auth.login.access_denied'));
        }
        return;
      }
      if (!mounted) return;

      TextInput.finishAutofillContext();
      context.go('/welcome');
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onLocaleChanged(String code) async {
    if (code == _lang || _loading) return;
    setState(() => _lang = code);
    await AppLocalizations.load(code);
    if (!mounted) return;
    widget.onSetLocale(Locale(code));
  }

  void _onThemeChanged(ThemeMode mode) {
    if (mode == _themeMode || _loading) return;
    setState(() => _themeMode = mode);
    widget.onSetTheme(mode);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      body: AppBackground(
        imageAsset: 'assets/images/login_bg.png',
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: GlassCard(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(32, 36, 32, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Logo(color: colors.accentPrimary),
                      const SizedBox(height: 14),
                      Text(
                        AppLocalizations.t('brand'),
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.t('auth.login.subtitle'),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: colors.textMuted),
                      ),
                      const SizedBox(height: 28),

                      AutofillGroup(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GlassTextField(
                              controller: _emailController,
                              hint: AppLocalizations.t('auth.login.email_hint'),
                              icon: Icons.mail_outline,
                              enabled: !_loading,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 12),
                            GlassTextField(
                              controller: _passwordController,
                              hint: AppLocalizations.t('auth.login.password_hint'),
                              icon: Icons.lock_outline,
                              isPassword: true,
                              enabled: !_loading,
                              autofillHints: const [AutofillHints.password],
                              textInputAction: TextInputAction.done,
                              onSubmitted: _login,
                            ),
                          ],
                        ),
                      ),

                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        ErrorBanner(_error!),
                      ],

                      const SizedBox(height: 18),
                      PrimaryButton(
                        label: AppLocalizations.t('auth.login.button'),
                        loading: _loading,
                        onPressed: _login,
                      ),

                      const SizedBox(height: 20),
                      Divider(color: colors.glassBorder),
                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_locales.isNotEmpty)
                            GlassDropdown<String>(
                              icon: Icons.language,
                              value: _locales.any((l) => l.code == _lang)
                                  ? _lang
                                  : _locales.first.code,
                              items: _locales.map((l) => l.code).toList(),
                              itemLabel: (code) =>
                                  _locales.firstWhere((l) => l.code == code).name,
                              enabled: !_loading,
                              onChanged: _onLocaleChanged,
                            )
                          else
                            const SizedBox.shrink(),
                          GlassDropdown<ThemeMode>(
                            icon: Icons.dark_mode_outlined,
                            value: _themeMode,
                            items: const [
                              ThemeMode.system,
                              ThemeMode.light,
                              ThemeMode.dark,
                            ],
                            itemLabel: (mode) => switch (mode) {
                              ThemeMode.system => AppLocalizations.t('theme.system'),
                              ThemeMode.light => AppLocalizations.t('theme.light'),
                              ThemeMode.dark => AppLocalizations.t('theme.dark'),
                            },
                            enabled: !_loading,
                            onChanged: _onThemeChanged,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 16,
                        runSpacing: 4,
                        children: [
                          _LinkText(
                            label: AppLocalizations.t('auth.login.terms'),
                            onTap: () => _openUrl(termsUrl),
                          ),
                          _LinkText(
                            label: AppLocalizations.t('auth.login.privacy'),
                            onTap: () => _openUrl(privacyUrl),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icon/splash_logo.png',
      width: 84,
      height: 84,
      errorBuilder: (context, error, stack) =>
          Icon(Icons.shield_outlined, color: color, size: 40),
    );
  }
}

class _LinkText extends StatelessWidget {
  const _LinkText({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: colors.textMuted,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
