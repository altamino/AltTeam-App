import 'package:flutter/material.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/admin_header.dart';
import '../../../core/api/repositories/altteam.dart';
import '../../../core/api/repositories/search.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/storage.dart';
import '../../../core/api/objects/args/roles.dart';

class AdminRolesScreen extends StatefulWidget {
  const AdminRolesScreen({super.key});

  @override
  State<AdminRolesScreen> createState() => _AdminRolesScreenState();
}

class _AdminRolesScreenState extends State<AdminRolesScreen> {
  final _altTeamRepo = AltTemRepository();
  final _searchRepo = SearchRepository();
  final _searchController = TextEditingController();

  bool _isAccessDenied = false;
  bool _isLoading = true;

  List<dynamic> _teamMembers = [];
  List<dynamic> _searchResults = [];
  bool _isSearching = false;

  static const List<int> _editableRoles = [
    RoleTypes.roleUser,
    RoleTypes.roleAltAminoMod,
    RoleTypes.roleAltAminoAdmin,
    RoleTypes.roleAltAminoStaff,
  ];

  @override
  void initState() {
    super.initState();
    _checkAccessAndLoadData();
  }

  Future<void> _checkAccessAndLoadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final teamData = await _altTeamRepo.getTeam();
      if (!mounted) return;
      setState(() {
        _teamMembers = teamData['userProfileList'] ?? [];
        _isAccessDenied = false;
        _isLoading = false;
        if (Storage.role != RoleTypes.roleAltAminoStaff) {
          _isAccessDenied = true;
        } else {
          _isAccessDenied = false;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAccessDenied = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);
    try {
      final result = await _searchRepo.searchUser(q: query);
      if (!mounted) return;
      setState(() {
        _searchResults = result['userProfileList'] ?? [];
      });
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(context, e.toString(), type: SnackType.error);
    } finally {
      if (!mounted) return;
      setState(() => _isSearching = false);
    }
  }

  Future<void> _openEditDialog(Map<String, dynamic> user, {bool isExistingMember = false}) async {
    final colors = AppColors.of(context);
    final dialogBg = Theme.of(context).dialogTheme.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor;

    final int rawRole = user['role'] ?? RoleTypes.roleUser;
    final bool isRoleEditableHere = _editableRoles.contains(rawRole);

    if (isExistingMember && !isRoleEditableHere) {
      AppSnackbar.show(
        context,
        AppLocalizations.t('admin.roles.role_not_editable'),
        type: SnackType.error,
      );
      return;
    }

    final int initialRole = isRoleEditableHere ? rawRole : RoleTypes.roleUser;
    int selectedRole = initialRole;

    final tagsController = TextEditingController(
      text: (user['extensions']['tagList'] as List?)?.join(', ') ?? '',
    );
    bool isTeamMember = user['extensions']['isMemberOfTeamAmino'] ?? false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: dialogBg.withValues(alpha: 0.95),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            isExistingMember
                ? AppLocalizations.t('admin.roles.edit_title')
                : AppLocalizations.t('admin.roles.assign_title'),
            style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundImage: user['icon'] != null ? NetworkImage(user['icon']) : null,
                    child: user['icon'] == null ? const Icon(Icons.person) : null,
                  ),
                  title: Text(user['nickname'] ?? '', style: TextStyle(color: colors.textPrimary)),
                  subtitle: Text('@${user['aminoId'] ?? ''}', style: TextStyle(color: colors.textMuted)),
                ),
                const SizedBox(height: 16),
                Text(AppLocalizations.t('admin.roles.field_role'), style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.w500)),
                DropdownButton<int>(
                  value: selectedRole,
                  isExpanded: true,
                  dropdownColor: dialogBg,
                  items: [
                    DropdownMenuItem(value: RoleTypes.roleUser, child: Text(AppLocalizations.t('admin.roles.role_user'))),
                    DropdownMenuItem(value: RoleTypes.roleAltAminoMod, child: Text(AppLocalizations.t('admin.roles.role_moderator'))),
                    DropdownMenuItem(value: RoleTypes.roleAltAminoAdmin, child: Text(AppLocalizations.t('admin.roles.role_administrator'))),
                    DropdownMenuItem(value: RoleTypes.roleAltAminoStaff, child: Text(AppLocalizations.t('admin.roles.role_staff'))),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedRole = val);
                  },
                ),
                const SizedBox(height: 16),
                Text(AppLocalizations.t('admin.roles.field_tags'), style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.w500)),
                TextField(
                  controller: tagsController,
                  style: TextStyle(color: colors.textPrimary),
                  decoration: InputDecoration(hintText: AppLocalizations.t('admin.roles.tags_hint')),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: isTeamMember,
                      onChanged: (val) {
                        if (val != null) setDialogState(() => isTeamMember = val);
                      },
                    ),
                    Text(AppLocalizations.t('admin.roles.field_team_member'), style: TextStyle(color: colors.textPrimary)),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.t('common.cancel'), style: TextStyle(color: colors.textMuted)),
            ),
            TextButton(
              onPressed: () async {
                final tags = tagsController.text
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();

                try {
                  await _altTeamRepo.editTeamMember(
                    userId: user['uid'],
                    role: (isRoleEditableHere && selectedRole != initialRole) ? selectedRole : null,
                    tagList: tags,
                    isMemberOfTeamAmino: isTeamMember,
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  _checkAccessAndLoadData();
                  AppSnackbar.show(context, AppLocalizations.t('admin.roles.success'));
                } catch (e) {
                  if (!context.mounted) return;
                  AppSnackbar.show(context, e.toString(), type: SnackType.error);
                }
              },
              child: Text(AppLocalizations.t('common.save'), style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
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
              AdminHeader(title: AppLocalizations.t('admin.roles.title')),
              Expanded(child: _buildMainContent(colors)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(AppPalette colors) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_isAccessDenied) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.gpp_bad_outlined, size: 64, color: colors.error),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.t('admin.roles.denied_title'),
              style: TextStyle(color: colors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.t('admin.roles.denied_subtitle'),
              style: TextStyle(color: colors.textMuted, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelColor: colors.accentPrimary,
            unselectedLabelColor: colors.textMuted,
            indicatorColor: colors.accentPrimary,
            tabs: [
              Tab(text: AppLocalizations.t('admin.roles.tab_current')),
              Tab(text: AppLocalizations.t('admin.roles.tab_search')),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildTeamList(colors),
                _buildSearchTab(colors),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamList(AppPalette colors) {
    if (_teamMembers.isEmpty) {
      return Center(child: Text(AppLocalizations.t('admin.roles.empty_team')));
    }

    return ListView.builder(
      itemCount: _teamMembers.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final member = _teamMembers[index];
        final tags = (member["extensions"]['tagList'] as List?)?.join(', ') ?? '';

        return Card(
          color: colors.glassFillStrong,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: member['icon'] != null ? NetworkImage(member['icon']) : null,
              child: member['icon'] == null ? const Icon(Icons.person) : null,
            ),
            title: Text(member['nickname'] ?? '', style: TextStyle(color: colors.textPrimary)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${AppLocalizations.t('admin.roles.role_label')}: ${member['role']}', style: TextStyle(color: colors.textSecondary)),
                if (tags.isNotEmpty)
                  Text('${AppLocalizations.t('admin.roles.tags_label')}: $tags', style: TextStyle(color: colors.accentPrimary, fontSize: 12)),
              ],
            ),
            trailing: const Icon(Icons.edit_outlined),
            onTap: () => _openEditDialog(member, isExistingMember: true),
          ),
        );
      },
    );
  }

  Widget _buildSearchTab(AppPalette colors) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            style: TextStyle(color: colors.textPrimary),
            decoration: InputDecoration(
              hintText: AppLocalizations.t('admin.roles.search_hint'),
              hintStyle: TextStyle(color: colors.textMuted),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => _searchUsers(_searchController.text),
              ),
            ),
            onSubmitted: _searchUsers,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                    ? Center(child: Text(AppLocalizations.t('admin.roles.search_empty_placeholder'), style: TextStyle(color: colors.textMuted)))
                    : ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final rawUser = _searchResults[index];

                          final existingMember = _teamMembers.firstWhere(
                            (m) => m['uid'] == rawUser['uid'],
                            orElse: () => null,
                          );

                          final Map<String, dynamic> user = existingMember ?? rawUser;
                          final bool isTeamMember = existingMember != null;

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: user['icon'] != null ? NetworkImage(user['icon']) : null,
                              child: user['icon'] == null ? const Icon(Icons.person) : null,
                            ),
                            title: Text(user['nickname'] ?? '', style: TextStyle(color: colors.textPrimary)),
                            subtitle: Text(
                              isTeamMember
                                  ? '${AppLocalizations.t('admin.roles.role_label')}: ${user['role']}'
                                  : '@${user['aminoId'] ?? ''}',
                              style: TextStyle(color: isTeamMember ? colors.accentPrimary : colors.textMuted),
                            ),
                            trailing: Icon(isTeamMember ? Icons.edit_outlined : Icons.add_moderator_outlined),
                            onTap: () => _openEditDialog(user, isExistingMember: isTeamMember),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}