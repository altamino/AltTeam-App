import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/repositories/communities.dart';
import '../../core/api/repositories/links.dart';
import '../../core/api/repositories/search.dart';
import '../../core/api/repositories/users.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/admin_header.dart';
import '../../core/widgets/app_background.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/glass_dropdown.dart';
import '../../core/widgets/user_avatar.dart';
import '../../core/api/objects/args/objTypes.dart';
import '../../core/api/constants.dart';

enum _Segment { users, communities }

class ModerationSearchScreen extends StatefulWidget {
  const ModerationSearchScreen({super.key});

  @override
  State<ModerationSearchScreen> createState() => _ModerationSearchScreenState();
}

class _ModerationSearchScreenState extends State<ModerationSearchScreen> {
  static final _uuidRe = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );
  static final _digitsRe = RegExp(r'^\d+$');
  static final _aminoIdRe = RegExp(r'^[a-zA-Z0-9_.-]+$');
  static final _linkRe = RegExp(r'^https?://', caseSensitive: false);

  final _searchRepo = SearchRepository();
  final _linksRepo = LinksRepository();
  final _usersRepo = UsersRepository();
  final _comRepo = CommunitiesRepository();
  final _controller = TextEditingController();

  _Segment _segment = _Segment.users;
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;
  bool _searched = false;

  List<String> _languages = [];
  String? _lang;

  String _lastUserQuery = '';

  @override
  void initState() {
    super.initState();
    _loadLanguages();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadLanguages() async {
    try {
      final res = await _searchRepo.getAvailableLanguages();
      final langs = List<String>.from(res['supportedLanguages'] ?? []);
      if (!mounted) return;
      setState(() {
        _languages = langs;
        _lang = langs.isNotEmpty ? langs.first : null;
      });
    } catch (_) {}
  }

  String _clean(Object e) => e.toString().replaceFirst('Exception: ', '');

  bool _isLink(String q) => _linkRe.hasMatch(q) || q.contains('/u/');

  void _setSegment(_Segment s) {
    if (s == _segment) return;
    setState(() {
      _segment = s;
      _results = [];
      _searched = false;
    });
  }

  Future<void> _search() async {
    final raw = _controller.text.trim();
    if (raw.isEmpty || _loading) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _results = [];
      _searched = true;
    });

    try {
      if (_isLink(raw)) {
        await _openFromLink(raw);
      } else if (_segment == _Segment.users) {
        if (_uuidRe.hasMatch(raw)) {
          await _openUserById(raw);
        } else {
          await _searchUsers(raw);
        }
      } else {
        if (_digitsRe.hasMatch(raw)) {
          await _openCommunityById(int.parse(raw));
        } else {
          await _searchCommunities(raw);
        }
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(context, _clean(e), type: SnackType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openFromLink(String link) async {
    final data = await _linksRepo.getFromLink(link);
    final info = data['linkInfoV2']?['extensions']?['linkInfo'];
    if (info is! Map) {
      throw Exception(AppLocalizations.t('admin.moderation.errors.wrong_link'));
    }

    final type = info['objectType'];
    if (!mounted) return;

    if (type == ObjectTypes.profile) {
      final uid = info['objectId'];
      if (uid is! String || uid.isEmpty) {
        throw Exception(AppLocalizations.t('admin.moderation.errors.wrong_link'));
      }
      context.push('/user/$uid');
      return;
    }

    if (type == ObjectTypes.community) {
      final ndcId = info['ndcId'] is int
          ? info['ndcId'] as int
          : int.tryParse('${info['ndcId'] ?? info['objectId']}');
      if (ndcId == null) {
        throw Exception(AppLocalizations.t('admin.moderation.errors.wrong_link'));
      }
      context.push('/altacm/community/$ndcId');
      return;
    }

    throw Exception(AppLocalizations.t('admin.moderation.errors.wrong_link'));
  }

  Future<void> _openUserById(String uid) async {
    Map<String, dynamic> profile;
    try {
      profile = await _usersRepo.getUserProfile(uid, 0);
    } catch (_) {
      throw Exception(
          AppLocalizations.t('admin.moderation.errors.user_not_found'));
    }
    if (!mounted) return;
    context.push('/user/$uid', extra: profile);
  }

  Future<void> _openCommunityById(int ndcId) async {
    try {
      final info = await _comRepo.getCommunityInfo(ndcId);
      if (info['community'] == null) throw Exception();
    } catch (_) {
      throw Exception(
          AppLocalizations.t('admin.moderation.errors.community_not_found'));
    }
    if (!mounted) return;
    context.push('/altacm/community/$ndcId');
  }

  Future<void> _searchUsers(String q) async {
    _lastUserQuery = q;
    final res = await _searchRepo.searchUser(q: q, size: 30);
    final list = (res['userProfileList'] as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    if (!mounted) return;
    setState(() => _results = list);
  }

  Future<void> _refreshUsers() async {
    if (_segment != _Segment.users || _lastUserQuery.isEmpty) return;
    try {
      await _searchUsers(_lastUserQuery);
    } catch (_) {}
  }

  Future<void> _searchCommunities(String q) async {
    final res = await _searchRepo.searchCommunity(
      lang: _lang,
      q: q,
      start: 0,
      size: 30,
    );
    final list = (res['communityList'] as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    if (_aminoIdRe.hasMatch(q)) {
      final exact = await _findCommunityByAminoId(q);
      if (exact != null) {
        list.removeWhere((c) => c['ndcId'] == exact['ndcId']);
        list.insert(0, exact);
      }
    }

    if (!mounted) return;
    setState(() => _results = list);
  }

  Future<Map<String, dynamic>?> _findCommunityByAminoId(String id) async {
    try {
      final data = await _linksRepo.getFromLink('$baseAltAminoUrl/c/$id');
      final info = data['linkInfoV2']?['extensions']?['linkInfo'];
      if (info is! Map || info['objectType'] != ObjectTypes.community) {
        return null;
      }
      final ndcId = int.tryParse('${info['ndcId'] ?? info['objectId']}');
      if (ndcId == null) return null;
      final res = await _comRepo.getCommunityInfo(ndcId);
      final c = res['community'];
      if (c is! Map) return null;
      return {...Map<String, dynamic>.from(c), 'ndcId': ndcId};
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isUsers = _segment == _Segment.users;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              AdminHeader(title: AppLocalizations.t('admin.moderation.title')),
              Expanded(
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    24 + MediaQuery.of(context).padding.bottom,
                  ),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _Segmented(
                            isUsers: isUsers,
                            onChanged: (u) => _setSegment(
                                u ? _Segment.users : _Segment.communities),
                          ),
                        ),
                        if (!isUsers && _languages.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          GlassDropdown<String>(
                            icon: Icons.language,
                            value: _lang ?? _languages.first,
                            items: _languages,
                            itemLabel: (l) => l.toUpperCase(),
                            onChanged: (l) {
                              if (l != null) setState(() => _lang = l);
                            },
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: colors.glassFill,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colors.glassBorder),
                      ),
                      child: TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _search(),
                        onChanged: (_) => setState(() {}),
                        cursorColor: colors.accentPrimary,
                        style:
                            TextStyle(color: colors.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: AppLocalizations.t(isUsers
                              ? 'admin.moderation.hint.users'
                              : 'admin.moderation.hint.communities'),
                          hintStyle:
                              TextStyle(color: colors.textMuted, fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          prefixIcon: Icon(Icons.search_rounded,
                              color: colors.textMuted, size: 22),
                          suffixIcon: _controller.text.isEmpty
                              ? null
                              : IconButton(
                                  icon: Icon(Icons.close_rounded,
                                      color: colors.textMuted, size: 20),
                                  onPressed: () => setState(() {
                                    _controller.clear();
                                    _results = [];
                                    _searched = false;
                                  }),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _search,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: colors.accentPrimary,
                          disabledBackgroundColor:
                              colors.accentPrimary.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: _loading
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colors.onAccent,
                                ),
                              )
                            : Icon(Icons.search_rounded,
                                size: 20, color: colors.onAccent),
                        label: Text(
                          AppLocalizations.t('admin.moderation.button'),
                          style: TextStyle(
                            color: colors.onAccent,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    ..._buildResults(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildResults() {
    if (!_searched) {
      return [
        _Hint(
          icon: Icons.manage_search_rounded,
          text: AppLocalizations.t('admin.moderation.idle'),
        ),
      ];
    }
    if (_loading) return const [];
    if (_results.isEmpty) {
      return [
        _Hint(
          icon: Icons.search_off_rounded,
          text: AppLocalizations.t('admin.moderation.empty'),
        ),
      ];
    }

    final isUsers = _segment == _Segment.users;
    return [
      for (final r in _results)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: isUsers
              ? _UserCard(
                  user: r,
                  onTap: () async {
                    final uid = r['uid'] as String?;
                    if (uid == null) return;
                    await context.push('/user/$uid', extra: r);
                    if (mounted) _refreshUsers();
                  },
                )
              : _CommunityCard(
                  community: r,
                  onTap: () {
                    final ndcId = r['ndcId'];
                    if (ndcId != null) context.push('/altacm/community/$ndcId');
                  },
                ),
        ),
    ];
  }
}

String? _cleanIcon(dynamic raw) {
  if (raw is! String) return null;
  final v = raw.trim();
  return v.startsWith('http') ? v : null;
}

class _Segmented extends StatelessWidget {
  const _Segmented({required this.isUsers, required this.onChanged});
  final bool isUsers;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    Widget seg(bool users, IconData icon, String label) {
      final selected = users == isUsers;
      final color = selected ? colors.accentPrimary : colors.textMuted;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(users),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: selected
                  ? colors.accentPrimary.withValues(alpha: 0.16)
                  : Colors.transparent,
              border: Border.all(
                color: selected
                    ? colors.accentPrimary.withValues(alpha: 0.45)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.glassFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.glassBorder),
      ),
      child: Row(
        children: [
          seg(true, Icons.person_search_rounded,
              AppLocalizations.t('admin.moderation.segment.users')),
          seg(false, Icons.groups_rounded,
              AppLocalizations.t('admin.moderation.segment.communities')),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user, required this.onTap});
  final Map<String, dynamic> user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    const radius = BorderRadius.all(Radius.circular(18));

    final nickname = user['nickname'] as String? ??
        user['aminoId'] as String? ??
        AppLocalizations.t('admin.labels.unknown_user');
    final aminoId = user['aminoId'] as String?;
    final verified = user['verified'] == true;
    final banned = (user['status'] ?? 0) == 9;

    return Material(
      color: colors.glassFill,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: colors.glassBorder),
          ),
          child: Row(
            children: [
              UserAvatar(
                nickname: nickname,
                iconUrl: _cleanIcon(user['icon']),
                isVerified: verified,
                size: 46,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nickname,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (aminoId != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '@$aminoId',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: colors.textMuted, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              if (banned) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: colors.error.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    AppLocalizations.t('admin.user.banned'),
                    style: TextStyle(
                      color: colors.error,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: colors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommunityCard extends StatelessWidget {
  const _CommunityCard({required this.community, required this.onTap});
  final Map<String, dynamic> community;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    const radius = BorderRadius.all(Radius.circular(18));

    final name = community['name'] as String? ?? '';
    final icon = _cleanIcon(community['icon']);
    final members = community['membersCount'] ?? 0;

    return Material(
      color: colors.glassFill,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: colors.glassBorder),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: icon == null
                      ? Container(
                          color: colors.accentPrimary.withValues(alpha: 0.14),
                          child: Icon(Icons.groups_rounded,
                              color: colors.accentPrimary),
                        )
                      : Image.network(
                          icon,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(
                            color: colors.accentPrimary.withValues(alpha: 0.14),
                            child: Icon(Icons.groups_rounded,
                                color: colors.accentPrimary),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$members ${AppLocalizations.t('admin.community.members')}',
                      style: TextStyle(color: colors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.accentPrimary.withValues(alpha: 0.10),
            ),
            child: Icon(icon, size: 32, color: colors.accentPrimary),
          ),
          const SizedBox(height: 14),
          Text(
            text,
            textAlign: TextAlign.center,
            style:
                TextStyle(color: colors.textMuted, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }
}