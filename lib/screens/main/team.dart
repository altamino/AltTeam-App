import 'package:flutter/material.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/admin_header.dart';
import '../../core/widgets/user_avatar.dart';

class AdminTeamScreen extends StatelessWidget {
  const AdminTeamScreen({super.key});

  // TODO: replace with real team member data + stats from backend.
  static const _stubMembers = <_TeamMember>[];

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
              AdminHeader(title: AppLocalizations.t('admin.team.title')),
              Expanded(
                child: _stubMembers.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.groups_outlined, size: 40, color: colors.textMuted),
                              const SizedBox(height: 14),
                              Text(
                                AppLocalizations.t('admin.team.empty'),
                                textAlign: TextAlign.center,
                                style: TextStyle(color: colors.textMuted, fontSize: 13, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: _stubMembers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final m = _stubMembers[i];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colors.glassFill,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: colors.glassBorder),
                            ),
                            child: Row(
                              children: [
                                UserAvatar(nickname: m.nickname, iconUrl: m.iconUrl, size: 40),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    m.nickname,
                                    style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                                  ),
                                ),
                                Text(
                                  m.roleLabel,
                                  style: TextStyle(color: colors.textMuted, fontSize: 12),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamMember {
  final String nickname;
  final String? iconUrl;
  final String roleLabel;
  const _TeamMember(this.nickname, this.iconUrl, this.roleLabel);
}