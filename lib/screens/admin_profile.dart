import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/api/repositories/auth.dart';
import '../core/api/repositories/users.dart';
import '../core/l10n/app_localizations.dart';
import '../core/storage.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/glass_dropdown.dart';
import '../core/widgets/user_avatar.dart';

const int _roleAltAminoMod = 200;
const int _roleAltAminoAdmin = 201;
const int _roleFeed = 253;
const int _roleSystem = 254;
const int _roleAltAminoStaff = 555;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.onSetTheme, required this.onSetLocale});
  final void Function(ThemeMode) onSetTheme;
  final void Function(Locale) onSetLocale;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _usersRepo = UsersRepository();
  final _authRepo = AuthRepository();

  Map<String, dynamic>? _profile;
  bool _loading = true;
  bool _loggingOut = false;
  String? _error;

  late ThemeMode _themeMode;
  late String _lang;
  List<LocaleInfo> _locales = [];

  @override
  void initState() {
    super.initState();
    _themeMode = Storage.themeMode;
    _lang = Storage.locale;
    AppLocalizations.availableLocales().then((l) {
      if (mounted) setState(() => _locales = l);
    });
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final profile = await _usersRepo.get_user_profile(Storage.userId ?? '', 0);
      if (!mounted) return;
      setState(() { _profile = profile; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _onLocaleChanged(String code) async {
    if (code == _lang) return;
    setState(() => _lang = code);
    await AppLocalizations.load(code);
    if (!mounted) return;
    widget.onSetLocale(Locale(code));
  }

  void _onThemeChanged(ThemeMode mode) {
    if (mode == _themeMode) return;
    setState(() => _themeMode = mode);
    widget.onSetTheme(mode);
  }

  Future<void> _logout() async {
    setState(() => _loggingOut = true);
    try {
      await _authRepo.logout();
    } catch (_) {
    } finally {
      if (mounted) context.go('/login');
    }
  }

  String _roleLabel(int role) {
    switch (role) {
      case _roleAltAminoStaff:
        return AppLocalizations.t('profile.role.platform_staff');
      case _roleAltAminoAdmin:
        return AppLocalizations.t('profile.role.admin');
      case _roleAltAminoMod:
        return AppLocalizations.t('profile.role.moderator');
      case _roleFeed:
        return AppLocalizations.t('profile.role.feed');
      case _roleSystem:
        return AppLocalizations.t('profile.role.system');
      case 0:
        return AppLocalizations.t('profile.role.member');
      default:
        return AppLocalizations.t('profile.role.staff');
    }
  }

  Color? _roleColor(int role, AppPalette colors) {
    switch (role) {
      case _roleAltAminoStaff:
        return Colors.redAccent;
      case _roleAltAminoAdmin:
        return Colors.amber.shade700;
      case _roleAltAminoMod:
        return Colors.green;
      case _roleFeed:
        return Colors.blue;
      case _roleSystem:
        return Colors.deepPurpleAccent;
      case 0:
        return null;
      default:
        return colors.accentPrimary;
    }
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
              _buildHeader(colors),
              Expanded(child: _buildBody(colors)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppPalette colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: colors.glassFill,
        border: Border(bottom: BorderSide(color: colors.glassBorder)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: colors.textPrimary, size: 20),
            onPressed: () => context.pop(),
          ),
          Text(
            AppLocalizations.t('profile.title'),
            style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

Widget _buildBody(AppPalette colors) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: colors.accentPrimary));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, style: TextStyle(color: colors.error, fontSize: 13), textAlign: TextAlign.center),
        ),
      );
    }

    final p = _profile ?? {};
    final nickname = p['nickname'] as String? ?? '';
    final iconUrl = p['icon'] as String?;
    final isTeamMember = (p['extensions'] as Map<String, dynamic>?)?['isMemberOfTeamAmino'] as bool? ?? false;
    final role = p['role'] as int? ?? 0;
    final content = (p['content'] as String?)?.trim() ?? '';
    final createdTime = _formatDate(p['createdTime'] as String?);
    final modifiedTime = _formatDate(p['modifiedTime'] as String?);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      child: Column(
        children: [
          UserAvatar(nickname: nickname, iconUrl: iconUrl, isVerified: isTeamMember, size: 84),
          const SizedBox(height: 14),
          Text(
            nickname.isNotEmpty ? nickname : '—',
            style: TextStyle(color: colors.textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _badge(
                colors, 
                _roleLabel(role), 
                customColor: _roleColor(role, colors),
              ),
              if (isTeamMember) 
                _badge(
                  colors, 
                  AppLocalizations.t('profile.team_badge'), 
                  customColor: colors.accentPrimary,
                ),
            ],
          ),
          const SizedBox(height: 24),
          _infoCard(colors, [
            _InfoRow(AppLocalizations.t('profile.info.created'), createdTime),
            _InfoRow(AppLocalizations.t('profile.info.modified'), modifiedTime),
          ]),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              content.isNotEmpty ? content : AppLocalizations.t('profile.no_bio'),
              style: TextStyle(
                color: content.isNotEmpty ? colors.textSecondary : colors.textMuted,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Divider(color: colors.glassBorder),
          const SizedBox(height: 20),
          _settingsSection(colors),
          const SizedBox(height: 32),
          _logoutButton(colors),
        ],
      ),
    );
  }
  
  Widget _settingsSection(AppPalette colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            AppLocalizations.t('profile.settings'),
            style: TextStyle(color: colors.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _settingRow(
              colors,
              label: AppLocalizations.t('profile.theme'),
              child: GlassDropdown<ThemeMode>(
                icon: Icons.dark_mode_outlined,
                value: _themeMode,
                items: const [ThemeMode.system, ThemeMode.light, ThemeMode.dark],
                itemLabel: (mode) => switch (mode) {
                  ThemeMode.system => AppLocalizations.t('theme.system'),
                  ThemeMode.light => AppLocalizations.t('theme.light'),
                  ThemeMode.dark => AppLocalizations.t('theme.dark'),
                },
                onChanged: _onThemeChanged,
              ),
            ),
            const SizedBox(width: 12),
            if (_locales.isNotEmpty)
              _settingRow(
                colors,
                label: AppLocalizations.t('profile.language'),
                child: GlassDropdown<String>(
                  icon: Icons.language,
                  value: _locales.any((l) => l.code == _lang) ? _lang : _locales.first.code,
                  items: _locales.map((l) => l.code).toList(),
                  itemLabel: (code) => _locales.firstWhere((l) => l.code == code).name,
                  onChanged: _onLocaleChanged,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _settingRow(AppPalette colors, {required String label, required Widget child}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: colors.textMuted, fontSize: 11)),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  Widget _logoutButton(AppPalette colors) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton.icon(
        onPressed: _loggingOut ? null : _logout,
        icon: _loggingOut
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: colors.error),
              )
            : Icon(Icons.logout, size: 18, color: colors.error),
        label: Text(
          AppLocalizations.t('profile.logout'),
          style: TextStyle(color: colors.error, fontSize: 14, fontWeight: FontWeight.w500),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: colors.errorBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _infoCard(AppPalette colors, List<_InfoRow> rows) {
    return Container(
      decoration: BoxDecoration(
        color: colors.glassFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.glassBorder),
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(rows[i].label, style: TextStyle(color: colors.textMuted, fontSize: 13)),
                  Text(rows[i].value, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            if (i != rows.length - 1) Divider(height: 1, color: colors.glassBorder),
          ],
        ],
      ),
    );
  }
Widget _badge(AppPalette colors, String text, {Color? customColor}) {
    final hasCustomColor = customColor != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: hasCustomColor ? customColor.withOpacity(0.12) : colors.glassFillStrong,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: hasCustomColor ? customColor.withOpacity(0.35) : colors.glassBorder),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: hasCustomColor ? customColor : colors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return '—';
    }
  }
}

class _InfoRow {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);
}