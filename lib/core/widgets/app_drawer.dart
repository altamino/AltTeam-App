import 'dart:convert'; 
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import 'user_avatar.dart';
import '../api/objects/args/roles.dart';
import '../api/constants.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.nickname,
    required this.aminoId,
    this.iconUrl,
    this.isTeamMember = false,
    this.role = 0,
    this.isTelegramLinked = false,
  });

  final String nickname;
  final String aminoId;
  final String? iconUrl;
  final bool isTeamMember;
  final int role;
  final bool isTelegramLinked;

  void _openTelegramBot(BuildContext context, bool isLinkAccount) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final rawString = '$aminoId:$timestamp:${tgKey}';
    final bytes = utf8.encode(rawString);
    final base64Token = base64Url.encode(bytes).replaceAll('=', '');
    final Uri url;


    if (isLinkAccount) {
      url = Uri.parse('$tgBotUrl?start=linkAccount-$base64Token');
    } else {
      url = Uri.parse('$tgBotUrl?start=unlinkAccount-$base64Token');
    }
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.t('drawer.errors.fail_open_telegram'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final showAdmin = RoleTypes.isStaffRole(role);

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
                      onTap: () => context.push('/profile'),
                    ),
                    

                    if (showAdmin)
                      _item(
                        context,
                        colors,
                        Icons.chat_bubble_outline,
                        AppLocalizations.t('drawer.chats'),
                        onTap: () => context.push('/admin/chats'),
                      ),

                    if (!isTelegramLinked)
                      _item(
                        context,
                        colors,
                        Icons.telegram,
                        AppLocalizations.t('drawer.link_telegram'),
                        onTap: () {
                          _openTelegramBot(context, true); 
                        },
                      )
                      
                    else
                      _item(
                        context,
                        colors,
                        Icons.no_cell_outlined,
                        AppLocalizations.t('drawer.unlink_telegram'), 
                        onTap: () {
                          _openTelegramBot(context, false); 
                        },
                      ),


                    if (showAdmin) ...[
                      Divider(color: colors.glassBorder, height: 16),
                      _item(
                        context,
                        colors,
                        Icons.admin_panel_settings_outlined,
                        AppLocalizations.t('drawer.admin'),
                        onTap: () => context.push('/admin'),
                      ),
                      _item(
                        context,
                        colors,
                        Icons.groups_outlined,
                        AppLocalizations.t('drawer.team'),
                        onTap: () => context.push('/admin/team'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context,
    AppPalette colors,
    IconData icon,
    String label, {
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: colors.textSecondary, size: 20),
      title: Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
      onTap: () {
        Navigator.of(context).pop();
        onTap();
      },
    );
  }
}