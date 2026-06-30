import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/api/repositories/altacm.dart';
import '../../core/api/repositories/search.dart';
import '../../core/widgets/glass_dropdown.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/api/constants.dart';
import '../../core/api/objects/args/roles.dart';
import '../../core/storage.dart';

class AltAcmCreateCommunityScreen extends StatefulWidget {
  const AltAcmCreateCommunityScreen({super.key});

  @override
  State<AltAcmCreateCommunityScreen> createState() => _AltAcmCreateCommunityScreenState();
}

class _AltAcmCreateCommunityScreenState extends State<AltAcmCreateCommunityScreen> {
  final _altAcm = AltACMRepository();
  final _searchRepo = SearchRepository();
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
  List<dynamic> _userSearchResults = [];

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
      AppSnackbar.show(context, e.toString(), type: SnackType.error);
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _userSearchResults = []);
      return;
    }
    setState(() => _isSearchingUsers = true);
    try {
      final result = await _searchRepo.searchUser(q: query);
      if (!mounted) return;
      setState(() {
        _userSearchResults = result['userProfileList'] ?? [];
      });
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(context, e.toString(), type: SnackType.error);
    } finally {
      if (mounted) setState(() => _isSearchingUsers = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

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
      AppSnackbar.show(context, AppLocalizations.t('admin.community.create_success'));
      
      final dynamic newNdcId = response?['community']?['ndcId'];

      if (newNdcId != null) {
        context.pushReplacement('/altacm/community/$newNdcId');
      } else {
        context.pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(context, e.toString(), type: SnackType.error);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors.bgGradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context, colors),
              Expanded(
                child: _isLoadingLangs
                    ? Center(child: CircularProgressIndicator(color: colors.accentPrimary))
                    : SingleChildScrollView(
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTextField(
                                controller: _nameController,
                                label: AppLocalizations.t('admin.community.field_name'),
                                hint: AppLocalizations.t('admin.community.field_name_hint'),
                                colors: colors,
                                validator: (v) => v!.trim().isEmpty ? AppLocalizations.t('admin.community.err_empty') : null,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _aminoIdController,
                                label: AppLocalizations.t('admin.community.field_amino_id'),
                                hint: AppLocalizations.t('admin.community.field_amino_id_hint'),
                                colors: colors,
                                validator: (v) => v!.trim().isEmpty ? AppLocalizations.t('admin.community.err_empty') : null,
                              ),
                              const SizedBox(height: 16),
                              _buildLanguageSelector(colors),
                              if (_isStaff) ...[
                                const SizedBox(height: 16),
                                _buildUserSelectorSection(colors),
                              ],
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, AppPalette colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: colors.textPrimary, size: 20),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppLocalizations.t('admin.community.create_title'),
              style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _isSubmitting
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: colors.accentPrimary, strokeWidth: 2),
                  )
                : TextButton(
                    onPressed: _submit,
                    style: TextButton.styleFrom(
                      foregroundColor: colors.accentPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text(
                      AppLocalizations.t('common.save'),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required AppPalette colors,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          style: TextStyle(color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: colors.textMuted),
            filled: true,
            fillColor: colors.accentPrimary.withOpacity(0.06),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageSelector(AppPalette colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.t('admin.community.field_lang'), style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        if (_languages.isNotEmpty)
          GlassDropdown<String>(
            icon: Icons.language,
            value: _selectedLang ?? 'en',
            items: _languages,
            itemLabel: (l) => l.toUpperCase(),
            onChanged: (l) {
              if (l != null) setState(() => _selectedLang = l);
            },
          ),
      ],
    );
  }

  Widget _buildUserSelectorSection(AppPalette colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.t('admin.community.field_user'), style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        if (_selectedUser != null) ...[
          Card(
            color: colors.glassFillStrong,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: _selectedUser!['icon'] != null ? NetworkImage(_selectedUser!['icon']) : null,
                child: _selectedUser!['icon'] == null ? const Icon(Icons.person) : null,
              ),
              title: Text(_selectedUser!['nickname'] ?? '', style: TextStyle(color: colors.textPrimary)),
              subtitle: Text('@${_selectedUser!['aminoId'] ?? ''}', style: TextStyle(color: colors.textMuted)),
              trailing: IconButton(
                icon: Icon(Icons.close, color: colors.error),
                onPressed: () => setState(() => _selectedUser = null),
              ),
            ),
          ),
        ] else ...[
          TextField(
            controller: _userSearchController,
            style: TextStyle(color: colors.textPrimary),
            decoration: InputDecoration(
              hintText: AppLocalizations.t('admin.roles.search_hint'),
              hintStyle: TextStyle(color: colors.textMuted),
              filled: true,
              fillColor: colors.accentPrimary.withOpacity(0.06),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => _searchUsers(_userSearchController.text),
              ),
            ),
            onSubmitted: _searchUsers,
          ),
          if (_isSearchingUsers)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Center(child: CircularProgressIndicator(color: colors.accentPrimary)),
            )
          else if (_userSearchResults.isNotEmpty) ...[
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  color: colors.glassFillStrong,
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(), 
                    itemCount: _userSearchResults.length,
                    itemBuilder: (context, index) {
                      final u = _userSearchResults[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: u['icon'] != null ? NetworkImage(u['icon']) : null,
                          child: u['icon'] == null ? const Icon(Icons.person) : null,
                        ),
                        title: Text(u['nickname'] ?? '', style: TextStyle(color: colors.textPrimary)),
                        subtitle: Text('@${u['aminoId'] ?? ''}', style: TextStyle(color: colors.textMuted)),
                        onTap: () {
                          setState(() {
                            _selectedUser = u;
                            _userSearchResults = [];
                            _userSearchController.clear();
                          });
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }
}