import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../banned_users_page.dart';
import '../community_roles.dart';
import '../deps.dart';
import '../edit_community_controller.dart';
import '../edit_tab.dart';
import '../widgets/manage_member_sheet.dart';
import '../widgets/member_tile.dart';
import '../widgets/ui.dart';

class MembersTab extends EditTab {
  const MembersTab();

  @override
  String get id => 'members';
  @override
  IconData get icon => Icons.people_alt_rounded;
  @override
  String get titleKey => 'admin.community.tab_users';

  @override
  bool get showSaveBar => false;

  @override
  Widget build(BuildContext context, EditCommunityController c) {
    final m = c.members;

    return ListenableBuilder(
      listenable: m,
      builder: (context, _) {
        final colors = AppColors.of(context);
        final myRole = c.viewerNdcRole;

        return TabScroll(
          children: [
            if (myRole != null) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: InfoPill(
                  icon: CommunityRoles.icon(myRole),
                  text:
                      '${AppLocalizations.t('admin.community.your_role')}: ${CommunityRoles.label(myRole)}',
                  color: CommunityRoles.color(colors, myRole),
                ),
              ),
              const SizedBox(height: 12),
            ],
            LabeledField(
              controller: m.searchField,
              hint: AppLocalizations.t('admin.community.search_users_hint'),
              prefixIcon: Icons.search_rounded,
              textInputAction: TextInputAction.search,
              onChanged: m.onQueryChanged,
              onSubmitted: m.search,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BannedUsersPage(ndcId: c.ndcId),
                  ),
                ),
                icon: const Icon(Icons.block_rounded),
                label: Text(AppLocalizations.t('admin.community.banned_users')),
              ),
            ),
            const SizedBox(height: 8),
            if (m.loading)
              Padding(
                padding: const EdgeInsets.only(top: 48),
                child: Center(
                  child: CircularProgressIndicator(color: colors.accentPrimary),
                ),
              )
            else if (m.users.isEmpty)
              EmptyState(
                icon: m.query.isEmpty
                    ? Icons.person_search_rounded
                    : Icons.search_off_rounded,
                text: AppLocalizations.t(m.query.isEmpty
                    ? 'admin.community.search_users_hint'
                    : 'admin.community.search_users_empty'),
              )
            else
              for (final u in m.users)
                MemberTile(
                  user: u,
                  isSelf: m.isSelf(u),
                  onOpen: () => _openProfile(context, c, u),
                  onManage: (m.canChangeRole(u) || m.canTransfer(u))
                      ? () => _manage(context, c, u)
                      : null,
                ),
          ],
        );
      },
    );
  }

  Future<void> _openProfile(
    BuildContext context,
    EditCommunityController c,
    Map<String, dynamic> user,
  ) async {
    final uid = user['uid']?.toString();
    if (uid == null || uid.isEmpty) return;
    await context.push('/user/$uid?ndcId=${c.ndcId}');
    c.members.afterProfileVisit();
  }

  Future<void> _manage(
    BuildContext context,
    EditCommunityController c,
    Map<String, dynamic> user,
  ) async {
    final m = c.members;

    final action = await showManageMemberSheet(
      context,
      user: user,
      canChangeRole: m.canChangeRole(user),
      canTransfer: m.canTransfer(user),
    );
    if (action == null || !context.mounted) return;

    if (action.transfer) {
      final ok = await showConfirmDialog(
        context,
        title: AppLocalizations.t('admin.community.transfer_agent_title'),
        message: AppLocalizations.t('admin.community.transfer_agent_message'),
        confirmLabel:
            AppLocalizations.t('admin.community.transfer_agent_confirm'),
        destructive: true,
      );
      if (ok == true) await m.transferAgent(user);
    } else if (action.role != null &&
        action.role != CommunityRoles.parse(user['role'])) {
      await m.changeRole(user, action.role!);
    }
  }
}