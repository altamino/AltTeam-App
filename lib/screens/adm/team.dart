import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/admin_header.dart';
import '../../core/widgets/user_avatar.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/api/repositories/users.dart';
import '../../core/api/objects/args/roles.dart';
import '../../core/api/constants.dart';

class AdminTeamScreen extends StatefulWidget {
  const AdminTeamScreen({super.key});

  @override
  State<AdminTeamScreen> createState() => _AdminTeamScreenState();
}

class _AdminTeamScreenState extends State<AdminTeamScreen> {
  final _usersRepo = UsersRepository();

  List<_TeamMember> _members = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await _usersRepo.getAltTeam();
      if (!mounted) return;
      
      final parsedMembers = list.map<_TeamMember>(_TeamMember.fromJson).toList();
      
      parsedMembers.sort((a, b) => b.reputation.compareTo(a.reputation));

      setState(() {
        _members = parsedMembers;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  String _roleLabel(int role) {
    switch (role) {
      case RoleTypes.roleAltAminoStaff:
        return AppLocalizations.t('profile.role.platform_staff');
      case RoleTypes.roleAltAminoAdmin:
        return AppLocalizations.t('profile.role.admin');
      case RoleTypes.roleAltAminoMod:
        return AppLocalizations.t('profile.role.moderator');
      case RoleTypes.roleFeed:
        return AppLocalizations.t('profile.role.feed');
      case RoleTypes.roleSystem:
        return AppLocalizations.t('profile.role.system');
      case 0:
        return AppLocalizations.t('profile.role.member');
      default:
        return AppLocalizations.t('profile.role.staff');
    }
  }

  Color? _roleColor(int role, AppPalette colors) {
    switch (role) {
      case RoleTypes.roleAltAminoStaff:
        return Colors.redAccent;
      case RoleTypes.roleAltAminoAdmin:
        return Colors.amber.shade700;
      case RoleTypes.roleAltAminoMod:
        return Colors.green;
      case RoleTypes.roleFeed:
        return Colors.blue;
      case RoleTypes.roleSystem:
        return Colors.deepPurpleAccent;
      case 0:
        return null;
      default:
        return colors.accentPrimary;
    }
  }

  void _openTelegram(int telegramId, BuildContext context) async {
      final appUrl = Uri.parse('tg://openmessage?user_id=$telegramId');
      final webUrl = Uri.parse('https://t.me/user?id=$telegramId');

      try {
        if (await canLaunchUrl(appUrl)) {
          await launchUrl(appUrl, mode: LaunchMode.externalApplication);
          return;
        }

        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      } catch (_) {
        if (!context.mounted) return;
        AppSnackbar.show(
          context,
          AppLocalizations.t('admin.team.errors.open_tg'),
          type: SnackType.error,
        );
      }
    }

  void _openAltAmino(String aminoId, BuildContext context) async {
    final url = Uri.parse('$baseAltAminoUrl/u/$aminoId');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (!context.mounted) return;
      AppSnackbar.show(
        context,
        AppLocalizations.t('admin.team.errors.open_amino'),
        type: SnackType.error,
      );
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
              AdminHeader(title: AppLocalizations.t('admin.team.title')),
              Expanded(child: _buildBody(colors)),
            ],
          ),
        ),
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

    if (_members.isEmpty) {
      return Center(
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
      );
    }

    return RefreshIndicator(
      color: colors.accentPrimary,
      backgroundColor: colors.glassFill,
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _members.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _memberTile(colors, _members[i]),
      ),
    );
  }

Widget _memberTile(AppPalette colors, _TeamMember m) {
    final hasTelegram = m.telegramId != null;
    final hasAmino = m.aminoId.isNotEmpty;
    final hasActions = hasTelegram || hasAmino;

    return Container(
      decoration: BoxDecoration(
        color: colors.glassFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.glassBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UserAvatar(nickname: m.nickname, iconUrl: m.iconUrl, size: 46),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.nickname,
                        style: TextStyle(color: colors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _badge(colors, _roleLabel(m.role), customColor: _roleColor(m.role, colors)),
                          ...m.tagList.map((tag) => _badge(colors, tag, customColor: colors.accentPrimary)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: colors.glassFillStrong,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colors.glassBorder),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, size: 16, color: colors.accentPrimary),
                      const SizedBox(height: 2),
                      Text(
                        '${m.reputation}',
                        style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (hasActions) ...[
            Divider(color: colors.glassBorder, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  if (hasTelegram)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: TextButton.icon(
                          onPressed: () => _openTelegram(m.telegramId!, context),
                          icon: const Icon(Icons.telegram, size: 18),
                          label: Text(AppLocalizations.t('admin.team.action.telegram'), style: const TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blue.shade400,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ),
                  if (hasAmino)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: TextButton.icon(
                          onPressed: () => _openAltAmino(m.aminoId, context),
                          icon: const Icon(Icons.link, size: 18),
                          label: Text(AppLocalizations.t('admin.team.action.amino'), style: const TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            foregroundColor: colors.accentPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  Widget _badge(AppPalette colors, String text, {Color? customColor}) {
    final hasCustomColor = customColor != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: hasCustomColor ? customColor.withOpacity(0.12) : colors.glassFillStrong,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: hasCustomColor ? customColor.withOpacity(0.35) : colors.glassBorder),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: hasCustomColor ? customColor : colors.textSecondary,
          fontSize: 10.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _TeamMember {
  final String id;
  final String aminoId;
  final int? telegramId;
  final String nickname;
  final String? iconUrl;
  final int role;
  final int reputation;
  final List<String> tagList; 

  const _TeamMember({
    required this.id,
    required this.aminoId,
    this.telegramId,
    required this.nickname,
    this.iconUrl,
    required this.role,
    required this.reputation,
    required this.tagList,
  });

  factory _TeamMember.fromJson(Map<String, dynamic> json) {
    final tagsRaw = json['extensions']['tagList'] as List<dynamic>? ?? [];
    final List<String> tags = tagsRaw.map((e) => e.toString()).toList();

    return _TeamMember(
      id: json['uid'] as String? ?? '',
      aminoId: json['aminoId'] as String? ?? '',
      telegramId: json['telegramId'] as int?,
      nickname: json['nickname'] as String? ?? '—',
      iconUrl: json['icon'] as String?,
      role: json['role'] as int? ?? 0,
      reputation: json['reputation'] as int? ?? 0,
      tagList: tags,
    );
  }
}