import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/api/repositories/users.dart';
import '../core/l10n/app_localizations.dart';
import '../core/storage.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/user_avatar.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _usersRepo = UsersRepository();

  Map<String, dynamic>? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
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

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final nickname = _profile?['nickname'] as String? ?? '';
    final iconUrl = _profile?['icon'] as String?;
    final isTeamMember = (_profile?['extensions'] as Map<String, dynamic>?)?['isMemberOfTeamAmino'] as bool? ?? false;

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
              _buildHeader(colors, nickname, iconUrl, isTeamMember),
              Expanded(
                child: _error != null
                    ? Center(
                        child: Text(_error!, style: TextStyle(color: colors.error, fontSize: 13)),
                      )
                    : _buildContent(colors, nickname),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppPalette colors, String nickname, String? iconUrl, bool isTeamMember) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: colors.glassFill,
        border: Border(bottom: BorderSide(color: colors.glassBorder)),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, color: colors.accentPrimary, size: 20),
          const SizedBox(width: 8),
          Text(
            AppLocalizations.t('auth.login.brand'),
            style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          if (_loading)
            SizedBox(
              width: 34,
              height: 34,
              child: Padding(
                padding: const EdgeInsets.all(7),
                child: CircularProgressIndicator(strokeWidth: 2, color: colors.textMuted),
              ),
            )
          else
            Row(
              children: [
                if (nickname.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Text(nickname, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                  ),
                UserAvatar(
                  nickname: nickname,
                  iconUrl: iconUrl,
                  isVerified: isTeamMember,
                  size: 34,
                  onTap: () => context.push('/profile'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildContent(AppPalette colors, String nickname) {
    return Center(
      child: Text(
        nickname.isNotEmpty
            ? AppLocalizations.t('welcome.greeting', args: {'name': nickname})
            : AppLocalizations.t('welcome.greeting_anon'),
        style: TextStyle(fontSize: 22, color: colors.textPrimary, fontWeight: FontWeight.w500),
      ),
    );
  }
}