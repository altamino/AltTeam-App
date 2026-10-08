import 'package:flutter/material.dart';

import '../community_roles.dart';
import '../deps.dart';
import 'ui.dart';

class MemberTile extends StatelessWidget {
  const MemberTile({
    super.key,
    required this.user,
    required this.isSelf,
    required this.onOpen,
    this.onManage,
  });

  final Map<String, dynamic> user;
  final bool isSelf;
  final VoidCallback onOpen;

  final VoidCallback? onManage;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final role = CommunityRoles.parse(user['role']);
    final roleColor = CommunityRoles.color(colors, role);
    final isBanned = user['status'] == 9 || user['membershipStatus'] == 3;
    final highlighted = role != RoleTypes.roleUser;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colors.glassFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.glassBorder),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            child: Row(
              children: [
                RoundAvatar(
                  url: user['icon'],
                  radius: 24,
                  ringColor: highlighted ? roleColor : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (user['nickname'] ?? '').toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          InfoPill(
                            icon: CommunityRoles.icon(role),
                            text: CommunityRoles.label(role),
                            color: roleColor,
                          ),
                          if (isSelf)
                            InfoPill(
                              icon: Icons.person_pin_rounded,
                              text: AppLocalizations.t(
                                  'admin.community.badge_you'),
                              color: colors.accentPrimary,
                            ),
                          if (isBanned)
                            InfoPill(
                              icon: Icons.block_rounded,
                              text: AppLocalizations.t(
                                  'admin.community.badge_banned'),
                              color: colors.error,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (onManage != null)
                  IconButton(
                    onPressed: onManage,
                    style: IconButton.styleFrom(
                      backgroundColor:
                          colors.accentPrimary.withValues(alpha: 0.12),
                    ),
                    icon: Icon(Icons.manage_accounts_rounded,
                        color: colors.accentPrimary, size: 22),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(Icons.chevron_right_rounded,
                        color: colors.textMuted, size: 26),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}