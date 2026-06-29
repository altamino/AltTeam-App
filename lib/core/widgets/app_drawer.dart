import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../api/constants.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import 'user_avatar.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.nickname,
    this.iconUrl,
    this.isTeamMember = false,
    this.role = 0,
  });

  final String nickname;
  final String? iconUrl;
  final bool isTeamMember;
  final int role;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final showAdmin = adminRoles.contains(role);

    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors.bgGradient,
          ),
          border: Border(right: BorderSide(color: colors.glassBorder)),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Row(
                  children: [
                    UserAvatar(nickname: nickname, iconUrl: iconUrl, isVerified: isTeamMember, size: 44),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        nickname.isNotEmpty ? nickname : '—',
                        style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: colors.glassBorder, height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _item(
                      context,
                      colors,
                      Icons.person_outline,
                      AppLocalizations.t('drawer.profile'),
                      '/profile',
                    ),
                    if (showAdmin)
                      _item(
                        context,
                        colors,
                        Icons.admin_panel_settings_outlined,
                        AppLocalizations.t('drawer.admin'),
                        '/admin',
                      ),
                    if (showAdmin)
                      _item(
                        context,
                        colors,
                        Icons.groups_outlined,
                        AppLocalizations.t('drawer.team'),
                        '/admin/team',
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

  Widget _item(BuildContext context, AppPalette colors, IconData icon, String label, String route) {
    return ListTile(
      leading: Icon(icon, color: colors.textSecondary, size: 20),
      title: Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
      onTap: () {
        Navigator.of(context).pop();
        context.push(route);
      },
    );
  }
}