import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'package:url_launcher/url_launcher.dart';
import '../core/api/objects/args/roles.dart';
import '../core/api/repositories/auth.dart';
import '../core/l10n/app_localizations.dart';
import '../core/storage.dart';
import '../core/api/constants.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/glass_dropdown.dart';
import 'package:flutter/services.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onSetTheme, required this.onSetLocale});
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
  bool _obscure = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _themeMode = Storage.themeMode;
    _lang = Storage.locale;
    AppLocalizations.availableLocales().then((l) => setState(() => _locales = l));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _openUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = AppLocalizations.t('auth.login.fill_all_fields'));
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _authRepo.login(email, password);
      final role = res['userProfile']?['role'] as int? ?? 0;
      if (!RoleTypes.isStaffRole(role) && adminsOnly) {
        await _authRepo.logout();
        setState(() => _error = AppLocalizations.t('auth.login.access_denied'));
        return;
      }
      if (!mounted) return;

      TextInput.finishAutofillContext(); 

      context.go('/welcome');
    } catch (e) {
      setState(() => _error = e.toString());
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors.bgGradient,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -100,
              left: -60,
              child: _glow(320, colors.ambientGlow),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                    child: Container(
                      width: 360,
                      decoration: colors.glassCard(radius: 20),
                      padding: const EdgeInsets.fromLTRB(32, 40, 32, 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: colors.accentPrimary.withOpacity(0.16),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: colors.accentPrimary.withOpacity(0.35)),
                            ),
                            child: Icon(Icons.shield_outlined, color: colors.accentPrimary, size: 24),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            AppLocalizations.t('auth.login.brand'),
                            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600, color: colors.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppLocalizations.t('auth.login.subtitle'),
                            style: TextStyle(fontSize: 13, color: colors.textMuted),
                          ),
                          const SizedBox(height: 28),

                          AutofillGroup(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _glassField(
                                  colors: colors,
                                  controller: _emailController,
                                  hint: AppLocalizations.t('auth.login.email_hint'),
                                  icon: Icons.mail_outline,
                                  enabled: !_loading,
                                  keyboardType: TextInputType.emailAddress,
                                  autofillHints: const [AutofillHints.email],
                                ),
                                const SizedBox(height: 12),
                                _glassField(
                                  colors: colors,
                                  controller: _passwordController,
                                  hint: AppLocalizations.t('auth.login.password_hint'),
                                  icon: Icons.lock_outline,
                                  obscure: _obscure,
                                  enabled: !_loading,
                                  keyboardType: TextInputType.visiblePassword,
                                  autofillHints: const [AutofillHints.password],
                                  suffix: IconButton(
                                    icon: Icon(
                                      _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      size: 18,
                                      color: colors.textMuted,
                                    ),
                                    onPressed: () => setState(() => _obscure = !_obscure),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: colors.errorBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: colors.errorBorder),
                              ),
                              child: Text(_error!, style: TextStyle(fontSize: 13, color: colors.error)),
                            ),
                          ],

                          const SizedBox(height: 18),

                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: DecoratedBox(
                              decoration: colors.primaryButton(),
                              child: TextButton(
                                onPressed: _loading ? null : _login,
                                style: TextButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: _loading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : Text(
                                        AppLocalizations.t('auth.login.button'),
                                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                                      ),
                              ),
                            ),
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
                                  value: _locales.any((l) => l.code == _lang) ? _lang : _locales.first.code,
                                  items: _locales.map((l) => l.code).toList(),
                                  itemLabel: (code) => _locales.firstWhere((l) => l.code == code).name,
                                  enabled: !_loading,
                                  onChanged: _onLocaleChanged,
                                )
                              else
                                const SizedBox.shrink(),
                              GlassDropdown<ThemeMode>(
                                icon: Icons.dark_mode_outlined,
                                value: _themeMode,
                                items: const [ThemeMode.system, ThemeMode.light, ThemeMode.dark],
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
                              InkWell(
                                onTap: () => _openUrl(termsUrl),
                                child: Text(
                                  AppLocalizations.t('auth.login.terms'),
                                  style: TextStyle(fontSize: 11, color: colors.textMuted, decoration: TextDecoration.underline),
                                ),
                              ),
                              InkWell(
                                onTap: () => _openUrl(privacyUrl),
                                child: Text(
                                  AppLocalizations.t('auth.login.privacy'),
                                  style: TextStyle(fontSize: 11, color: colors.textMuted, decoration: TextDecoration.underline),
                                ),
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
          ],
        ),
      ),
    );
  }

  Widget _glow(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }

  Widget _glassField({
    required AppPalette colors,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    bool enabled = true,
    TextInputType? keyboardType,
    Widget? suffix,
    Iterable<String>? autofillHints,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colors.glassFillStrong,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.glassBorder),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        enabled: enabled,
        keyboardType: keyboardType,
        autofillHints: autofillHints,
        style: TextStyle(color: colors.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: colors.textMuted, fontSize: 15),
          prefixIcon: Icon(icon, size: 18, color: colors.textMuted),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
        ),
      ),
    );
  }
}