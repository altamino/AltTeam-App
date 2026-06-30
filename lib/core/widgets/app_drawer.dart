import 'dart:convert'; 
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import 'user_avatar.dart';
import 'app_snackbar.dart';
import '../api/objects/args/roles.dart';
import '../api/constants.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.nickname,
    required this.aminoId,
    this.iconUrl,
    this.isVerified = false,
    this.role = 0,
    this.isTelegramLinked = false,
  });

  final String nickname;
  final String aminoId;
  final String? iconUrl;
  final bool isVerified;
  final int role;
  final bool isTelegramLinked;

  void _openTelegramBot(BuildContext context, bool isLinkAccount) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final rawString = '$aminoId:$timestamp:$tgKey';
    final bytes = utf8.encode(rawString);
    final base64Token = base64Url.encode(bytes).replaceAll('=', '');
    
    final payload = isLinkAccount ? 'linkAccount-$base64Token' : 'unlinkAccount-$base64Token';
    final botUsername = tgBotUrl.split('/').last;

    final appUrl = Uri.parse('tg://resolve?domain=$botUsername&start=$payload');
    final webUrl = Uri.parse('https://t.me/$botUsername?start=$payload');

    try {
      if (await canLaunchUrl(appUrl)) {
        await launchUrl(appUrl, mode: LaunchMode.externalApplication);
        return;
      }
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        AppSnackbar.show(
          context,
          AppLocalizations.t('drawer.errors.fail_open_telegram'),
          type: SnackType.error,
        );
      }
    }
  }

  void _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

void _showAboutDialog(BuildContext context, AppPalette colors) {
    final dialogBg = Theme.of(context).dialogBackgroundColor;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dialogBg.withOpacity(0.95),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colors.glassBorder.withOpacity(0.4)),
        ),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: colors.accentPrimary, size: 22),
            const SizedBox(width: 10),
            Text(
              AppLocalizations.t('drawer.about.title'),
              style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.t('drawer.about.description'),
              style: TextStyle(color: colors.textPrimary, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 12),
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final version = snapshot.data?.version ?? '—';
                final buildNumber = snapshot.data?.buildNumber ?? '—';
                return Text(
                  AppLocalizations.t('drawer.about.version', args: {'version': '$version ($buildNumber)'}),
                  style: TextStyle(color: colors.textMuted, fontSize: 12),
                );
              },
            ),
            const SizedBox(height: 20),
            Center(
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  Navigator.of(context).pop();
                  _openUrl('https://t.me/Alx0rrHub');
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.telegram, size: 16, color: colors.accentPrimary),
                      const SizedBox(width: 6),
                      Text(
                        AppLocalizations.t('drawer.about.developer_link'),
                        style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: colors.textSecondary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              AppLocalizations.t('drawer.about.close'),
              style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
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
                    UserAvatar(nickname: nickname, iconUrl: iconUrl, isVerified: isVerified, size: 44),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        nickname.isNotEmpty ? nickname : '?',
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
                        onTap: () => _openTelegramBot(context, true),
                      )
                    else
                      _item(
                        context,
                        colors,
                        Icons.no_cell_outlined,
                        AppLocalizations.t('drawer.unlink_telegram'), 
                        onTap: () => _openTelegramBot(context, false),
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

                    Divider(color: colors.glassBorder, height: 16),
                    _item(
                      context,
                      colors,
                      Icons.report_gmailerrorred_outlined,
                      AppLocalizations.t('drawer.reports'),
                      onTap: () {
                        if (showAdmin) {
                          context.push('/admin/reports');
                        } else {
                          context.push('/reports');
                        }
                      },
                    ),
                    _item(
                      context,
                      colors,
                      Icons.layers_outlined,
                      AppLocalizations.t('drawer.alt_acm'),
                      onTap: () {
                        context.push('/altacm');
                      },
                    ),
                  ],
                ),
              ),

              Divider(color: colors.glassBorder, height: 1),
              _item(
                context,
                colors,
                Icons.info_outline,
                AppLocalizations.t('drawer.about_app'),
                onTap: () => _showAboutDialog(context, colors),
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