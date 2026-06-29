import 'package:flutter/material.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/admin_header.dart';
import '../../core/widgets/user_avatar.dart';
import '../../core/api/repositories/users.dart';

const int _roleAltAminoMod = 200;
const int _roleAltAminoAdmin = 201;
const int _roleFeed = 253;
const int _roleSystem = 254;
const int _roleAltAminoStaff = 555;

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
        padding: const EdgeInsets.all(20),
        itemCount: _members.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) => _memberTile(colors, _members[i]),
      ),
    );
  }

  Widget _memberTile(AppPalette colors, _TeamMember m) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.glassFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.glassBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          UserAvatar(nickname: m.nickname, iconUrl: m.iconUrl, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.nickname,
                  style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _badge(colors, _roleLabel(m.role), customColor: _roleColor(m.role, colors)),
                      ...m.tagList.map((tag) => Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: _badge(colors, tag, customColor: colors.accentPrimary),
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_rounded, size: 16, color: colors.accentPrimary),
              const SizedBox(height: 2),
              Text(
                '${m.reputation}',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
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
  final String nickname;
  final String? iconUrl;
  final int role;
  final int reputation;
  final List<String> tagList; 

  const _TeamMember({
    required this.id,
    required this.nickname,
    this.iconUrl,
    required this.role,
    required this.reputation,
    required this.tagList,
  });

  factory _TeamMember.fromJson(Map<String, dynamic> json) {
    final tagsRaw = json['tagList'] as List<dynamic>? ?? [];
    final List<String> tags = tagsRaw.map((e) => e.toString()).toList();

    return _TeamMember(
      id: json['id'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '—',
      iconUrl: json['icon'] as String?,
      role: json['role'] as int? ?? 0,
      reputation: json['reputation'] as int? ?? 0,
      tagList: tags,
    );
  }
}