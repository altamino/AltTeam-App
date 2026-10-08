import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/constants.dart';
import '../../core/api/objects/args/objTypes.dart';
import '../../core/api/objects/args/roles.dart';
import '../../core/api/repositories/altacm.dart';
import '../../core/api/repositories/links.dart';
import '../../core/api/repositories/search.dart';
import '../../core/api/repositories/users.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/storage.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/admin_header.dart';
import '../../core/widgets/app_background.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/glass_dropdown.dart';
import '../../core/widgets/user_avatar.dart';

class AltAcmCreateCommunityScreen extends StatefulWidget {
  const AltAcmCreateCommunityScreen({super.key});

  @override
  State<AltAcmCreateCommunityScreen> createState() =>
      _AltAcmCreateCommunityScreenState();
}

class _AltAcmCreateCommunityScreenState
    extends State<AltAcmCreateCommunityScreen> {
  static final _aminoIdRe = RegExp(r'^[a-zA-Z0-9_.-]+$');
  static final _linkRe = RegExp(r'^https?://', caseSensitive: false);

  final _altAcm = AltACMRepository();
  final _searchRepo = SearchRepository();
  final _linksRepo = LinksRepository();
  final _usersRepo = UsersRepository();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _aminoIdController = TextEditingController();
  final _userSearchController = TextEditingController();

  late final bool _isStaff = RoleTypes.isStaffRole(Storage.role);

  String? _selectedLang;
  List<String> _languages = [];
  Map<String, dynamic>? _selectedUser;

  bool _isLoadingLangs = true;
  bool _isSearchingUsers = false;
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _userSearchResults = [];

  @override
  void initState() {
    super.initState();
    _loadLanguages();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aminoIdController.dispose();
    _userSearchController.dispose();
    super.dispose();
  }

  String _clean(Object e) => e.toString().replaceFirst('Exception: ', '');

  Future<void> _loadLanguages() async {
    try {
      final res = await _searchRepo.getAvailableLanguages();
      final langs = List<String>.from(res['supportedLanguages'] ?? []);
      if (!mounted) return;
      setState(() {
        _languages = langs;
        _selectedLang = langs.isNotEmpty ? langs.first : null;
        _isLoadingLangs = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingLangs = false);
      AppSnackbar.show(context, _clean(e), type: SnackType.error);
    }
  }

  bool _isLink(String q) => _linkRe.hasMatch(q) || q.contains('/u/');

  Future<Map<String, dynamic>> _resolveUserLink(String link) async {
    final data = await _linksRepo.getFromLink(link);
    final info = data['linkInfoV2']?['extensions']?['linkInfo'];
    final uid = info is Map ? info['objectId'] : null;
    if (info is! Map ||
        info['objectType'] != ObjectTypes.profile ||
        uid is! String ||
        uid.isEmpty) {
      throw Exception(AppLocalizations.t('admin.moderation.errors.wrong_link'));
    }
    try {
      final profile = await _usersRepo.getUserProfile(uid, 0);
      return {...Map<String, dynamic>.from(profile), 'uid': uid};
    } catch (_) {
      throw Exception(
          AppLocalizations.t('admin.moderation.errors.user_not_found'));
    }
  }

  Future<void> _searchUsers(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      setState(() => _userSearchResults = []);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _isSearchingUsers = true);
    try {
      if (_isLink(q)) {
        final user = await _resolveUserLink(q);
        if (!mounted) return;
        setState(() {
          _selectedUser = user;
          _userSearchResults = [];
          _userSearchController.clear();
        });
        return;
      }

      final result = await _searchRepo.searchUser(q: q);
      final list = (result['userProfileList'] as List? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      if (!mounted) return;
      setState(() => _userSearchResults = list);
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(context, _clean(e), type: SnackType.error);
    } finally {
      if (mounted) setState(() => _isSearchingUsers = false);
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _isSubmitting = true);
    try {
      final String? userUrl = (_isStaff && _selectedUser != null)
          ? "$baseAltAminoUrl/u/${_selectedUser!['aminoId'] ?? ''}"
          : null;

      final response = await _altAcm.createCommunity(
        _nameController.text.trim(),
        _aminoIdController.text.trim(),
        _selectedLang,
        userUrl,
      );

      if (!mounted) return;
      AppSnackbar.show(
          context, AppLocalizations.t('admin.community.create_success'));

      final dynamic newNdcId = response?['community']?['ndcId'];
      if (newNdcId != null) {
        context.pushReplacement('/altacm/community/$newNdcId');
      } else {
        context.pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(context, _clean(e), type: SnackType.error);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              AdminHeader(
                  title: AppLocalizations.t('admin.community.create_title')),
              Expanded(
                child: _isLoadingLangs
                    ? Center(
                        child: CircularProgressIndicator(
                            color: colors.accentPrimary))
                    : ListView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.fromLTRB(
                          16,
                          12,
                          16,
                          24 + MediaQuery.of(context).padding.bottom,
                        ),
                        children: [
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _Field(
                                  controller: _nameController,
                                  label: AppLocalizations.t(
                                      'admin.community.field_name'),
                                  hint: AppLocalizations.t(
                                      'admin.community.field_name_hint'),
                                  validator: (v) => (v ?? '').trim().isEmpty
                                      ? AppLocalizations.t(
                                          'admin.community.err_empty')
                                      : null,
                                ),
                                const SizedBox(height: 16),
                                _Field(
                                  controller: _aminoIdController,
                                  label: AppLocalizations.t(
                                      'admin.community.field_amino_id'),
                                  hint: AppLocalizations.t(
                                      'admin.community.field_amino_id_hint'),
                                  validator: (v) {
                                    final s = (v ?? '').trim();
                                    if (s.isEmpty) {
                                      return AppLocalizations.t(
                                          'admin.community.err_empty');
                                    }
                                    if (!_aminoIdRe.hasMatch(s)) {
                                      return AppLocalizations.t(
                                          'admin.community.err_amino_id');
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildLanguageSelector(colors),
                                if (_isStaff) ...[
                                  const SizedBox(height: 16),
                                  _buildUserSelector(colors),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: _isSubmitting ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: colors.accentPrimary,
                                disabledBackgroundColor:
                                    colors.accentPrimary.withValues(alpha: 0.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: _isSubmitting
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: colors.onAccent,
                                      ),
                                    )
                                  : Icon(Icons.add_rounded,
                                      size: 20, color: colors.onAccent),
                              label: Text(
                                AppLocalizations.t('common.save'),
                                style: TextStyle(
                                  color: colors.onAccent,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(AppPalette colors) {
    if (_languages.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(AppLocalizations.t('admin.community.field_lang')),
        const SizedBox(height: 6),
        GlassDropdown<String>(
          icon: Icons.language,
          value: _selectedLang ?? _languages.first,
          items: _languages,
          itemLabel: (l) => l.toUpperCase(),
          onChanged: (l) {
            if (l != null) setState(() => _selectedLang = l);
          },
        ),
      ],
    );
  }

  Widget _buildUserSelector(AppPalette colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(AppLocalizations.t('admin.community.field_user')),
        const SizedBox(height: 6),
        if (_selectedUser != null)
          _UserTile(
            user: _selectedUser!,
            trailing: IconButton(
              icon: Icon(Icons.close_rounded, color: colors.error),
              onPressed: () => setState(() => _selectedUser = null),
            ),
          )
        else ...[
          Container(
            decoration: BoxDecoration(
              color: colors.glassFill,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.glassBorder),
            ),
            child: TextField(
              controller: _userSearchController,
              textInputAction: TextInputAction.search,
              onSubmitted: _searchUsers,
              cursorColor: colors.accentPrimary,
              style: TextStyle(color: colors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: AppLocalizations.t('admin.roles.search_hint'),
                hintStyle: TextStyle(color: colors.textMuted, fontSize: 14),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                prefixIcon: Icon(Icons.search_rounded,
                    color: colors.textMuted, size: 22),
                suffixIcon: IconButton(
                  icon: Icon(Icons.arrow_forward_rounded,
                      color: colors.accentPrimary, size: 20),
                  onPressed: () => _searchUsers(_userSearchController.text),
                ),
              ),
            ),
          ),
          if (_isSearchingUsers)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Center(
                child: CircularProgressIndicator(color: colors.accentPrimary),
              ),
            )
          else if (_userSearchResults.isNotEmpty) ...[
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemCount: _userSearchResults.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final u = _userSearchResults[i];
                  return _UserTile(
                    user: u,
                    onTap: () => setState(() {
                      _selectedUser = u;
                      _userSearchResults = [];
                      _userSearchController.clear();
                    }),
                  );
                },
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Text(
      text,
      style: TextStyle(
        color: colors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final radius = BorderRadius.circular(16);

    OutlineInputBorder border(Color c) => OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: c),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(label),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          cursorColor: colors.accentPrimary,
          style: TextStyle(color: colors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: colors.textMuted, fontSize: 14),
            filled: true,
            fillColor: colors.glassFill,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: border(colors.glassBorder),
            enabledBorder: border(colors.glassBorder),
            focusedBorder: border(colors.accentPrimary),
            errorBorder: border(colors.error),
            focusedErrorBorder: border(colors.error),
          ),
        ),
      ],
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user, this.onTap, this.trailing});
  final Map<String, dynamic> user;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    const radius = BorderRadius.all(Radius.circular(16));

    final nickname = user['nickname'] as String? ??
        user['aminoId'] as String? ??
        AppLocalizations.t('admin.labels.unknown_user');
    final aminoId = user['aminoId'] as String?;
    final icon = user['icon'];

    return Material(
      color: colors.glassFill,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: colors.glassBorder),
          ),
          child: Row(
            children: [
              UserAvatar(
                nickname: nickname,
                iconUrl: icon is String && icon.startsWith('http') ? icon : null,
                isVerified: user['verified'] == true,
                size: 42,
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
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (aminoId != null)
                      Text(
                        '@$aminoId',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: colors.textMuted, fontSize: 12),
                      ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}