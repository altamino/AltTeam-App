import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/admin_header.dart';
import '../../../core/api/repositories/altteam.dart';
import '../../../core/api/repositories/search.dart';
import '../../../core/api/repositories/links.dart';
import '../../../core/api/repositories/users.dart'; 
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/storage.dart';
import '../../../core/api/objects/args/roles.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/api/constants.dart';

class UserModerationScreen extends StatefulWidget {
  const UserModerationScreen({super.key});

  @override
  State<UserModerationScreen> createState() => _UserModerationScreenState();
}

class _UserModerationScreenState extends State<UserModerationScreen> with SingleTickerProviderStateMixin {
  final _altTeamRepo = AltTemRepository();
  final _searchRepo = SearchRepository();
  final _linkRepo = LinksRepository();
  final _usersRepo = UsersRepository(); 

  final _searchController = TextEditingController();
  final _emailResetController = TextEditingController();
  late TabController _tabController;

  bool _isLoading = false;
  bool _showCommunities = true;

  Map<String, dynamic>? _selectedUser;
  List<dynamic> _userCommunities = [];
  List<dynamic> _searchResults = [];

  final int _currentUserRole = Storage.role ?? 0;

  bool get _canResetPassword =>
      _currentUserRole == RoleTypes.roleAltAminoAdmin ||
      _currentUserRole == RoleTypes.roleSystem ||
      _currentUserRole == RoleTypes.roleAltAminoStaff;




bool get _isUserBanned => (_selectedUser?['status'] ?? 0) == 9;

Future<void> _toggleGlobalBan() async {
  final user = _selectedUser;
  if (user == null) return;
  final uid = user['uid'] as String?;
  if (uid == null) return;

  final willBan = !_isUserBanned;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(willBan
          ? AppLocalizations.t('admin.dialogs.ban_confirm_title')
          : AppLocalizations.t('admin.dialogs.unban_confirm_title')),
      content: Text(willBan
          ? AppLocalizations.t('admin.dialogs.ban_confirm_body')
          : AppLocalizations.t('admin.dialogs.unban_confirm_body')),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(AppLocalizations.t('common.cancel')),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: willBan ? Colors.red : null,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(willBan
              ? AppLocalizations.t('admin.buttons.confirm_ban')
              : AppLocalizations.t('admin.buttons.confirm_unban')),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  setState(() => _isLoading = true);
  try {
    await _altTeamRepo.setModerationStatus(
      type: 'user',
      objId: uid,
      disable: willBan,
    );
    if (!mounted) return;
    setState(() {
      _selectedUser = {
        ..._selectedUser!,
        "status": willBan ? 9 : 0,
      };
    });
    AppSnackbar.show(
      context,
      willBan
          ? AppLocalizations.t('admin.success.user_banned')
          : AppLocalizations.t('admin.success.user_unbanned'),
      type: SnackType.success,
    );
  } catch (e) {
    if (!mounted) return;
    AppSnackbar.show(context, e.toString().replaceAll("Exception: ", ""), type: SnackType.error);
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}




  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _canResetPassword ? 2 : 1, vsync: this);
    
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        FocusScope.of(context).unfocus();
      }
    });

    _searchController.addListener(_onSearchTextChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    _emailResetController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onSearchTextChanged() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _selectedUser = null;
        _showCommunities = true;
      });
    } else {
      if (_selectedUser != null) {
        setState(() {
          _selectedUser = null;
          _showCommunities = true;
        });
      }
    }
  }

  Future<void> _processSearch(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _searchResults = [];
      _selectedUser = null;
      _showCommunities = true;
    });

    try {
      if (cleanQuery.startsWith('http://') || cleanQuery.startsWith('https://') || cleanQuery.contains('/u/')) {
        final linkData = await _linkRepo.getFromLink(cleanQuery);
        final extensions = linkData['linkInfoV2']['extensions']?['linkInfo'];
        if (extensions == null || extensions['objectType'] != 0) {
          throw Exception(AppLocalizations.t('admin.errors.invalid_profile_link'));
        }
        final targetUid = extensions['objectId'] as String;
        
        Map<String, dynamic>? fullProfile;
        try {
          fullProfile = await _usersRepo.getUserProfile(targetUid, 0);
        } catch (_) {}

        await _selectUser(targetUid, profileData: fullProfile);
      } else {
        final searchData = await _searchRepo.searchUser(q: cleanQuery);
        final list = searchData['userProfileList'] as List?;

        if (list == null || list.isEmpty) {
          throw Exception(AppLocalizations.t('admin.roles.search_empty_placeholder'));
        }

        setState(() {
          _searchResults = list;
        });
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(context, e.toString().replaceAll("Exception: ", ""), type: SnackType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectUser(String uid, {Map<String, dynamic>? profileData}) async {
    setState(() {
      _isLoading = true;
      _searchResults = [];
      _userCommunities = [];
      _selectedUser = profileData != null
          ? _mapSearchProfile(profileData)
          : {
              "uid": uid,
              "aminoId": null,
              "nickname": "...",
              "icon": null,
              "role": 0,
              "verified": false,
              "onlineStatus": null,
              "status": 0,
              "tagList": const [],
            };
    });

    try {
      final commsData = await _altTeamRepo.getUserCommunities(uid);
      if (!mounted) return;

      setState(() {
        _userCommunities = commsData['communityList'] ?? [];

        if (profileData == null && _userCommunities.isNotEmpty) {
          final firstProfile = _userCommunities.first['userProfile'] ?? {};
          _selectedUser = {
            ..._selectedUser!,
            "nickname": firstProfile['nickname'] ?? _selectedUser!['nickname'],
            "icon": _cleanIcon(firstProfile['icon']) ?? _selectedUser!['icon'],
          };
        }
      });
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(context, AppLocalizations.t('admin.errors.communities_load_failed'), type: SnackType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _mapSearchProfile(Map<String, dynamic> p) {
    return {
      "uid": p['uid'],
      "aminoId": p['aminoId'],
      "nickname": p['nickname'] ?? p['aminoId'] ?? AppLocalizations.t('admin.labels.unknown_user'),
      "icon": _cleanIcon(p['icon']),
      "role": p['role'] ?? 0,
      "verified": p['verified'] == true,
      "onlineStatus": p['onlineStatus'],
      "status": p['status'] ?? 0,
      "tagList": (p['tagList'] as List?)?.cast<String>() ?? const [],
      "createdTime": p['createdTime'],
    };
  }
  String? _cleanIcon(dynamic raw) {
    if (raw is! String) return null;
    final v = raw.trim();
    if (v.isEmpty) return null;
    if (!v.startsWith('http')) return null;
    return v;
  }

  Future<void> _executeResetPassword() async {
    final email = _emailResetController.text.trim();
    if (email.isEmpty) {
      AppSnackbar.show(context, AppLocalizations.t('admin.errors.invalid_email'), type: SnackType.error);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      await _altTeamRepo.resetPasswordByEmail(email);
      if (!mounted) return;
      _emailResetController.clear();
      AppSnackbar.show(
        context, 
        "${AppLocalizations.t('admin.success.reset_instructions_sent')} $email", 
        type: SnackType.success,
      );
    } catch (e) {
      if (!mounted) return;
      final errorMsg = e.toString().replaceAll("Exception: ", "");
      AppSnackbar.show(context, errorMsg, type: SnackType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
              AdminHeader(title: AppLocalizations.t('admin.section.usr_moderation')),
              if (_canResetPassword)
                TabBar(
                  controller: _tabController,
                  labelColor: colors.accentPrimary,
                  unselectedLabelColor: colors.textMuted,
                  indicatorColor: colors.accentPrimary,
                  tabs: [
                    Tab(text: AppLocalizations.t('admin.tabs.search_and_manage')),
                    Tab(text: AppLocalizations.t('admin.tabs.password_reset')),
                  ],
                ),
              Expanded(
                child: _canResetPassword
                    ? TabBarView(
                        controller: _tabController,
                        children: [
                          _buildModerationTab(colors),
                          _buildPasswordResetTab(colors),
                        ],
                      )
                    : _buildModerationTab(colors),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModerationTab(AppPalette colors) {
    return Column(
      children: [
        _buildSearchInput(colors),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildMainContent(colors),
        ),
      ],
    );
  }

  Widget _buildMainContent(AppPalette colors) {
    if (_searchResults.isNotEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final user = _searchResults[index] as Map<String, dynamic>;
          final uid = user['uid'] as String?;
          final icon = _cleanIcon(user['icon']);
          return Card(
            color: colors.glassFill,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: icon != null ? NetworkImage(icon) : null,
                child: icon == null ? const Icon(Icons.person) : null,
              ),
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      user['nickname'] ?? AppLocalizations.t('admin.labels.unknown_user'), 
                      style: TextStyle(color: colors.textPrimary),
                    ),
                  ),
                  if (user['verified'] == true) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.verified, size: 14, color: colors.accentPrimary),
                  ],
                ],
              ),
              subtitle: Text(
                '@${user['aminoId'] ?? '-'} · UID: $uid',
                style: TextStyle(color: colors.textMuted, fontSize: 12),
              ),
              onTap: uid == null ? null : () => _selectUser(uid, profileData: user),
            ),
          );
        },
      );
    }

    if (_selectedUser != null) {
      return _buildProfileContent(colors);
    }

    return Center(
      child: Text(
        AppLocalizations.t('admin.roles.search_empty_placeholder'),
        style: TextStyle(color: colors.textMuted),
      ),
    );
  }

  Widget _buildPasswordResetTab(AppPalette colors) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
          color: colors.glassFillStrong,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.t('admin.password_reset.title'), 
                  style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  AppLocalizations.t('admin.password_reset.description'),
                  style: TextStyle(color: colors.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _emailResetController,
                  style: TextStyle(color: colors.textPrimary),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _executeResetPassword(),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.t('admin.password_reset.email_label'),
                    labelStyle: TextStyle(color: colors.textMuted),
                    hintText: "example@domain.com",
                    prefixIcon: const Icon(Icons.alternate_email_rounded),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.accentPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.mail_lock_outlined, size: 18),
                    label: Text(AppLocalizations.t('admin.password_reset.button_submit')),
                    onPressed: _isLoading ? null : _executeResetPassword,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchInput(AppPalette colors) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: colors.textPrimary),
        decoration: InputDecoration(
          hintText: AppLocalizations.t('admin.section.usr_moderation_desc'),
          hintStyle: TextStyle(color: colors.textMuted),
          suffixIcon: IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _processSearch(_searchController.text),
          ),
        ),
        onSubmitted: _processSearch,
      ),
    );
  }

Widget _buildProfileContent(AppPalette colors) {
    final user = _selectedUser!;
    final icon = _cleanIcon(user['icon']);
    final tags = (user['tagList'] as List?)?.cast<String>() ?? const [];
    final isOnline = user['onlineStatus'] == -1; //idk for now 
    final aminoId = user['aminoId'];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        Card(
          color: colors.glassFillStrong,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundImage: icon != null ? NetworkImage(icon) : null,
                      child: icon == null ? const Icon(Icons.person, size: 32) : null,
                    ),
                    if (user['onlineStatus'] != null)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: isOnline ? Colors.green : colors.textMuted,
                            shape: BoxShape.circle,
                            border: Border.all(color: colors.surfaceElevated, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    user['nickname'] ?? '',
                                    style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (user['verified'] == true) ...[
                                  const SizedBox(width: 6),
                                  Icon(Icons.verified, size: 16, color: colors.accentPrimary),
                                ],
                              ],
                            ),
                          ),
                          if (aminoId != null)
                            IconButton(
                              icon: Icon(Icons.open_in_new_rounded, color: colors.accentPrimary, size: 22),
                              tooltip: AppLocalizations.t('admin.tooltips.global_profile'),
                              onPressed: () async {
                                final globalUri = Uri.parse('$baseAltAminoUrl/u/$aminoId');
                                if (await canLaunchUrl(globalUri)) {
                                  await launchUrl(globalUri, mode: LaunchMode.externalApplication);
                                } else {
                                  if (!context.mounted) return;
                                  AppSnackbar.show(context, AppLocalizations.t('admin.errors.browser_launch_failed'), type: SnackType.error);
                                }
                              },
                            ),
                        ],
                      ),
                      Text(
                        aminoId != null ? '@$aminoId' : AppLocalizations.t('admin.labels.id_undefined'),
                        style: TextStyle(color: colors.accentPrimary, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      SelectableText('UID: ${user['uid'] ?? 'none'}', style: TextStyle(color: colors.textMuted, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        if (tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: tags.map((t) => Chip(
              label: Text(t, style: TextStyle(fontSize: 11, color: colors.textPrimary)),
              backgroundColor: colors.glassFill,
              visualDensity: VisualDensity.compact,
            )).toList(),
          ),
        ],

        const SizedBox(height: 16),
        Center(
          child: Text(
            AppLocalizations.t('admin.labels.account_actions'), 
            style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        const SizedBox(height: 8),
        
        Center(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isUserBanned ? colors.glassFill : colors.errorBg,
                  foregroundColor: _isUserBanned ? colors.textPrimary : colors.error,
                ),
                icon: Icon(_isUserBanned ? Icons.lock_open_rounded : Icons.shield_outlined, size: 16),
                label: Text(_isUserBanned
                    ? AppLocalizations.t('admin.buttons.remove_ban')
                    : AppLocalizations.t('admin.buttons.apply_sanctions')),
                onPressed: _isLoading ? null : _toggleGlobalBan,
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.accentPrimary,
                  side: BorderSide(color: colors.accentPrimary),
                ),
                icon: Icon(_showCommunities ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, size: 16),
                label: Text(_showCommunities 
                  ? AppLocalizations.t('admin.buttons.hide_communities') 
                  : "${AppLocalizations.t('admin.buttons.show_communities')} (${_userCommunities.length})"),
                onPressed: () {
                  setState(() {
                    _showCommunities = !_showCommunities;
                  });
                },
              ),
            ],
          ),
        ),

        if (_showCommunities) ...[
          const SizedBox(height: 24),
          Text(AppLocalizations.t('admin.labels.user_communities_list'), style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          if (_userCommunities.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Center(child: Text(AppLocalizations.t('admin.labels.communities_not_found'), style: TextStyle(color: colors.textMuted))),
            )
          else
            ..._userCommunities.map((com) {
              final profile = (com['userProfile'] as Map?) ?? {};
              final comIcon = _cleanIcon(com['icon']);
              final userIcon = _cleanIcon(profile['icon']);
              final ndcId = com['ndcId'];
              final isLeaderOrCurator = (profile['role'] ?? 0) > 0;
              
              final String staffSuffix = isLeaderOrCurator ? " · ${AppLocalizations.t('admin.labels.community_staff')}" : "";

              return Card(
                color: colors.glassFill,
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundImage: comIcon != null ? NetworkImage(comIcon) : null,
                      child: comIcon == null ? const Icon(Icons.public, size: 20) : null,
                    ),
                    title: Text(
                      com['name'] ?? AppLocalizations.t('admin.labels.no_title'), 
                      style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 10,
                            backgroundImage: userIcon != null ? NetworkImage(userIcon) : null,
                            child: userIcon == null ? const Icon(Icons.person, size: 10) : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "${profile['nickname'] ?? '-'}$staffSuffix",
                              style: TextStyle(color: colors.textMuted, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    trailing: Icon(Icons.open_in_new_rounded, color: colors.accentPrimary, size: 20),
                    onTap: ndcId == null
                        ? null
                        : () async {
                            final uri = Uri.parse(profile['linkData']?['linkInfoV2']?['extensions']?['linkInfo']?['shareURLFullPath']);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            } else {
                              if (!context.mounted) return;
                              AppSnackbar.show(context, AppLocalizations.t('admin.errors.link_open_failed'), type: SnackType.error);
                            }
                          },
                  ),
                ),
              );
            }),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

}