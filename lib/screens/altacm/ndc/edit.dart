import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cross_file/cross_file.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/api/repositories/altacm.dart';
import '../../../core/api/repositories/links.dart';
import '../../../core/api/repositories/theme_editor.dart';

import '../../../core/storage.dart';
import '../../../core/api/objects/args/roles.dart';

/// Редактирование настроек сообщества (ACM).
///
/// Важно про тему (.ndthemepack):
/// - "background"  -> фон community-хаба
/// - "titlebar"    -> ЛОГО В БОКОВОЙ ПАНЕЛИ (то, что видно слева при входе
///                    в комьюнити). Это НЕ основная иконка сообщества —
///                    основная иконка (avatar) грузится отдельно и
///                    отправляется как обычный `icon` в /altacm/.../edit.
///   (в decompiled-клиенте это поле titlebar-background-image, путают
///    с "logo" потому что выглядит как лого, но по факту titlebar)
class AltAcmEditCommunityScreen extends StatefulWidget {
  final Map<String, dynamic>? communityData;

  const AltAcmEditCommunityScreen({
    super.key,
    this.communityData,
  });

  @override
  State<AltAcmEditCommunityScreen> createState() => _AltAcmEditCommunityScreenState();
}

class _AltAcmEditCommunityScreenState extends State<AltAcmEditCommunityScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  late final TabController _tabController;

  // Базовые поля
  late TextEditingController _nameController;
  late TextEditingController _taglineController;
  late TextEditingController _aminoIdController;
  late TextEditingController _descriptionController;
  late TextEditingController _guidelinesController;
  late TextEditingController _welcomeMessageController;
  late TextEditingController _themeColorController;

  XFile? _selectedIconFile;
  String? _currentIconUrl;

  XFile? _selectedCoverFile;
  String? _currentCoverUrl;

  bool _welcomeMessageEnabled = false;

  // Настройки вступления/видимости — доступны лидеру/куратору,
  // НЕ являются staff-only.
  int _joinType = 0; // 0 - Open, 1 - ApprovalRequired, 2 - InviteOnly
  bool _hidden = false;

  // Единственное, что реально требует глобального стаффа — смена языка
  // сообщества (влияет на глобальные листинги/поиск).
  late bool _isStaff;
  late String _language;
  static const List<String> _availableLanguages = ['en', 'ru', 'es', 'ar'];

  // Тема — собирается с нуля, без выбора существующего .ndthemepack
  bool _themeEditingEnabled = false;
  XFile? _selectedThemeBackgroundFile; // background-image
  XFile? _selectedThemeTitlebarFile; // лого в боковой панели (titlebar)

  bool _isLoading = false;

  List<Tab> get _tabs => [
        Tab(text: AppLocalizations.t('admin.community.tab_general'), icon: const Icon(Icons.tune_rounded, size: 20)),
        Tab(text: AppLocalizations.t('admin.community.tab_media'), icon: const Icon(Icons.image_rounded, size: 20)),
        Tab(text: AppLocalizations.t('admin.community.tab_content'), icon: const Icon(Icons.article_rounded, size: 20)),
        Tab(text: AppLocalizations.t('admin.community.tab_theme'), icon: const Icon(Icons.palette_rounded, size: 20)),
        if (_isStaff)
          Tab(text: AppLocalizations.t('admin.community.tab_staff'), icon: const Icon(Icons.verified_user_rounded, size: 20)),
      ];

  @override
  void initState() {
    super.initState();

    _isStaff = RoleTypes.isStaffRole(Storage.role);
    _tabController = TabController(length: _isStaff ? 5 : 4, vsync: this);

    final data = widget.communityData;

    _nameController = TextEditingController(text: data?['name'] ?? '');
    _taglineController = TextEditingController(text: data?['tagline'] ?? '');
    _aminoIdController = TextEditingController(text: data?['endpoint'] ?? data?['aminoId'] ?? '');
    _descriptionController = TextEditingController(text: data?['description'] ?? '');
    _guidelinesController = TextEditingController(text: data?['guidelines'] ?? '');
    _themeColorController = TextEditingController(text: data?['themeColor'] ?? '');

    final configuration = (data?['configuration'] as Map?)?.cast<String, dynamic>() ?? {};
    _welcomeMessageController = TextEditingController(text: configuration['welcomeMessage'] ?? '');
    _welcomeMessageEnabled = configuration['welcomeMessageEnabled'] == true;

    _currentIconUrl = data?['icon'];
    _currentCoverUrl = data?['coverUrl'] ?? data?['cover'];

    _joinType = (configuration['joinType'] ?? data?['joinType'] ?? 0) is int
        ? (configuration['joinType'] ?? data?['joinType'] ?? 0)
        : int.tryParse('${configuration['joinType'] ?? data?['joinType'] ?? 0}') ?? 0;
    _hidden = (configuration['hidden'] ?? data?['hidden']) == true;

    final lang = (data?['lang'] ?? data?['language'])?.toString();
    _language = _availableLanguages.contains(lang) ? lang! : 'en';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _taglineController.dispose();
    _aminoIdController.dispose();
    _descriptionController.dispose();
    _guidelinesController.dispose();
    _welcomeMessageController.dispose();
    _themeColorController.dispose();
    super.dispose();
  }

  Future<void> _pickIcon() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512);
      if (image != null) setState(() => _selectedIconFile = image);
    } catch (e) {
      if (mounted) AppSnackbar.show(context, e.toString(), type: SnackType.error);
    }
  }

  Future<void> _pickCover() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1600);
      if (image != null) setState(() => _selectedCoverFile = image);
    } catch (e) {
      if (mounted) AppSnackbar.show(context, e.toString(), type: SnackType.error);
    }
  }

  Future<void> _pickThemeBackground() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1600);
      if (image != null) setState(() => _selectedThemeBackgroundFile = image);
    } catch (e) {
      if (mounted) AppSnackbar.show(context, e.toString(), type: SnackType.error);
    }
  }

  Future<void> _pickThemeTitlebar() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1600);
      if (image != null) setState(() => _selectedThemeTitlebarFile = image);
    } catch (e) {
      if (mounted) AppSnackbar.show(context, e.toString(), type: SnackType.error);
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final rawNdcId = widget.communityData?['ndcId'] ?? widget.communityData?['id'];
      if (rawNdcId == null) {
        throw Exception("ndcId / id not found in communityData");
      }
      final ndcId = int.parse(rawNdcId.toString());

      final acmRepo = AltACMRepository();
      final linksRepo = LinksRepository();

      // 1. Иконка (основная, НЕ из темы)
      String? uploadedIconUrl;
      if (_selectedIconFile != null) {
        final res = await linksRepo.uploadMedia(file: _selectedIconFile!);
        uploadedIconUrl = res['mediaValue'];
      }

      // 2. Обложка
      String? uploadedCoverUrl;
      if (_selectedCoverFile != null) {
        final res = await linksRepo.uploadMedia(file: _selectedCoverFile!);
        uploadedCoverUrl = res['mediaValue'];
      }

      // 3. Тема — background + лого в боковой панели (titlebar).
      //    Собирается с нуля прямо на клиенте, без выбора готового
      //    .ndthemepack, и загружается как новый архив темы.
      String? themeUrl;
      int? themeRevision;
      if (_themeEditingEnabled &&
          (_selectedThemeBackgroundFile != null || _selectedThemeTitlebarFile != null)) {
        final themeEditor = ThemeEditor.newTheme();

        if (_selectedThemeBackgroundFile != null) {
          themeEditor.injectImage(
            forWhat: 'background',
            newImageData: await _selectedThemeBackgroundFile!.readAsBytes(),
          );
        }
        if (_selectedThemeTitlebarFile != null) {
          themeEditor.injectImage(
            forWhat: 'titlebar', // = лого в боковой панели
            newImageData: await _selectedThemeTitlebarFile!.readAsBytes(),
          );
        }

        themeEditor.incrementRevision(); // 0 -> 1 для новой темы
        final zipBytes = themeEditor.rebuild();

        final uploadRes = await linksRepo.uploadThemeArchive(zipBytes: zipBytes, ndcId: ndcId);
        themeUrl = uploadRes['mediaValue'];
        themeRevision = themeEditor.revision;
      }

      // 4. Отправляем изменения сообщества.
      //    joinType/hidden — доступны любому лидеру, не гейтятся стаффом.
      //    language — единственное поле, требующее глобального стаффа.
      await acmRepo.editCommunity(
        ndcId,
        name: _nameController.text.trim(),
        aminoId: _aminoIdController.text.trim(),
        tagline: _taglineController.text.trim(),
        description: _emptyToNull(_descriptionController.text),
        guidelines: _emptyToNull(_guidelinesController.text),
        icon: uploadedIconUrl,
        coverUrl: uploadedCoverUrl,
        themeUrl: themeUrl,
        themeColor: _emptyToNull(_themeColorController.text),
        themeRevision: themeRevision,
        welcomeMessage: _emptyToNull(_welcomeMessageController.text),
        welcomeMessageEnabled: _welcomeMessageEnabled,
        joinType: _joinType,
        hidden: _hidden,
        language: _isStaff ? _language : null,
      );

      if (!mounted) return;

      AppSnackbar.show(
        context,
        AppLocalizations.t('admin.community.save_success'),
        type: SnackType.success,
      );

      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(context, e.toString(), type: SnackType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
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
              _buildAppBar(colors),
              _buildTabBar(colors),
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator(color: colors.accentPrimary))
                    : Form(
                        key: _formKey,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _tabScroll(_buildGeneralTab(colors)),
                            _tabScroll(_buildMediaTab(colors)),
                            _tabScroll(_buildContentTab(colors)),
                            _tabScroll(_buildThemeTab(colors)),
                            if (_isStaff) _tabScroll(_buildStaffTab(colors)),
                          ],
                        ),
                      ),
              ),
              if (!_isLoading) _buildSubmitButton(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabScroll(Widget child) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: child,
    );
  }

  Widget _buildAppBar(AppPalette colors) {
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
              AppLocalizations.t('admin.community.edit_title'),
              style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(AppPalette colors) {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      indicatorColor: colors.accentPrimary,
      labelColor: colors.textPrimary,
      unselectedLabelColor: colors.textMuted,
      tabAlignment: TabAlignment.start,
      tabs: _tabs,
    );
  }

  // ---------------- Вкладка: Основное ----------------

  Widget _buildGeneralTab(AppPalette colors) {
    return Column(
      children: [
        _buildIconPicker(colors),
        const SizedBox(height: 24),
        _glassWrap(
          colors,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fieldLabel(colors, AppLocalizations.t('admin.community.field_name')),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: AppLocalizations.t('admin.community.field_name_hint'),
                  hintStyle: TextStyle(color: colors.textMuted),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? AppLocalizations.t('admin.community.err_empty') : null,
              ),
              const SizedBox(height: 20),
              _fieldLabel(colors, AppLocalizations.t('admin.community.field_tagline')),
              const SizedBox(height: 8),
              TextFormField(
                controller: _taglineController,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: AppLocalizations.t('admin.community.field_tagline_hint'),
                  hintStyle: TextStyle(color: colors.textMuted),
                ),
              ),
              const SizedBox(height: 20),
              _fieldLabel(colors, AppLocalizations.t('admin.community.field_amino_id')),
              const SizedBox(height: 8),
              TextFormField(
                controller: _aminoIdController,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: AppLocalizations.t('admin.community.field_amino_id_hint'),
                  hintStyle: TextStyle(color: colors.textMuted),
                  prefixText: '@',
                  prefixStyle: TextStyle(color: colors.accentPrimary),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? AppLocalizations.t('admin.community.err_empty') : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _glassWrap(
          colors,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fieldLabel(colors, AppLocalizations.t('admin.community.field_join_type')),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: _joinType,
                dropdownColor: colors.bgGradient.last,
                style: TextStyle(color: colors.textPrimary),
                items: [
                  DropdownMenuItem(value: 0, child: Text(AppLocalizations.t('admin.community.join_type_open'))),
                  DropdownMenuItem(
                      value: 1, child: Text(AppLocalizations.t('admin.community.join_type_approval_required'))),
                  DropdownMenuItem(
                      value: 2, child: Text(AppLocalizations.t('admin.community.join_type_invite_only'))),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _joinType = val);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _fieldLabel(colors, AppLocalizations.t('admin.community.field_hidden'))),
                  Switch(
                    value: _hidden,
                    activeColor: colors.accentPrimary,
                    onChanged: (val) => setState(() => _hidden = val),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIconPicker(AppPalette colors) {
    ImageProvider? imageProvider;

    if (_selectedIconFile != null) {
      imageProvider = FileImage(File(_selectedIconFile!.path));
    } else if (_currentIconUrl != null && _currentIconUrl!.isNotEmpty) {
      imageProvider = NetworkImage(_currentIconUrl!);
    }

    return GestureDetector(
      onTap: _pickIcon,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: colors.textMuted.withOpacity(0.2),
            backgroundImage: imageProvider,
            child: imageProvider == null
                ? Icon(Icons.add_photo_alternate_rounded, size: 40, color: colors.textSecondary)
                : null,
          ),
          CircleAvatar(
            radius: 16,
            backgroundColor: colors.accentPrimary,
            child: const Icon(Icons.edit_rounded, size: 16, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // ---------------- Вкладка: Медиа ----------------

  Widget _buildMediaTab(AppPalette colors) {
    ImageProvider? imageProvider;
    if (_selectedCoverFile != null) {
      imageProvider = FileImage(File(_selectedCoverFile!.path));
    } else if (_currentCoverUrl != null && _currentCoverUrl!.isNotEmpty) {
      imageProvider = NetworkImage(_currentCoverUrl!);
    }

    return _glassWrap(
      colors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel(colors, AppLocalizations.t('admin.community.field_cover')),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _pickCover,
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: colors.textMuted.withOpacity(0.15),
                image: imageProvider != null ? DecorationImage(image: imageProvider, fit: BoxFit.cover) : null,
              ),
              child: imageProvider == null
                  ? Center(child: Icon(Icons.add_photo_alternate_rounded, size: 32, color: colors.textSecondary))
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Вкладка: Контент (описание/приветствие) ----------------

  Widget _buildContentTab(AppPalette colors) {
    return Column(
      children: [
        _glassWrap(
          colors,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fieldLabel(colors, AppLocalizations.t('admin.community.field_description')),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: AppLocalizations.t('admin.community.field_description_hint'),
                  hintStyle: TextStyle(color: colors.textMuted),
                ),
              ),
              const SizedBox(height: 20),
              _fieldLabel(colors, AppLocalizations.t('admin.community.field_guidelines')),
              const SizedBox(height: 8),
              TextFormField(
                controller: _guidelinesController,
                maxLines: 4,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: AppLocalizations.t('admin.community.field_guidelines_hint'),
                  hintStyle: TextStyle(color: colors.textMuted),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _glassWrap(
          colors,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: _fieldLabel(colors, AppLocalizations.t('admin.community.field_welcome_message'))),
                  Switch(
                    value: _welcomeMessageEnabled,
                    activeColor: colors.accentPrimary,
                    onChanged: (val) => setState(() => _welcomeMessageEnabled = val),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _welcomeMessageController,
                maxLines: 3,
                enabled: _welcomeMessageEnabled,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: AppLocalizations.t('admin.community.field_welcome_message_hint'),
                  hintStyle: TextStyle(color: colors.textMuted),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------- Вкладка: Тема ----------------

  Widget _buildThemeTab(AppPalette colors) {
    return _glassWrap(
      colors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _fieldLabel(colors, AppLocalizations.t('admin.community.field_theme'))),
              Switch(
                value: _themeEditingEnabled,
                activeColor: colors.accentPrimary,
                onChanged: (val) => setState(() => _themeEditingEnabled = val),
              ),
            ],
          ),
          if (_themeEditingEnabled) ...[
            const SizedBox(height: 16),
            _themeImageTile(
              colors,
              label: AppLocalizations.t('admin.community.field_theme_background'),
              file: _selectedThemeBackgroundFile,
              onTap: _pickThemeBackground,
            ),
            const SizedBox(height: 12),
            // "titlebar" в theme-паке — это лого в боковой панели,
            // не путать с основной иконкой сообщества (та во вкладке "Основное").
            _themeImageTile(
              colors,
              label: AppLocalizations.t('admin.community.field_theme_sidebar_logo'),
              file: _selectedThemeTitlebarFile,
              onTap: _pickThemeTitlebar,
            ),
            const SizedBox(height: 20),
            _fieldLabel(colors, AppLocalizations.t('admin.community.field_theme_color')),
            const SizedBox(height: 8),
            TextFormField(
              controller: _themeColorController,
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: '#RRGGBB',
                hintStyle: TextStyle(color: colors.textMuted),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return null;
                final hex = RegExp(r'^#([0-9a-fA-F]{6})$');
                return hex.hasMatch(val.trim())
                    ? null
                    : AppLocalizations.t('admin.community.err_invalid_color');
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _themeImageTile(
    AppPalette colors, {
    required String label,
    required XFile? file,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: colors.textMuted.withOpacity(0.12),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: file != null
                  ? Image.file(File(file.path), width: 44, height: 44, fit: BoxFit.cover)
                  : Container(
                      width: 44,
                      height: 44,
                      color: colors.textMuted.withOpacity(0.2),
                      child: Icon(Icons.image_rounded, color: colors.textSecondary, size: 20),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                file != null ? file.name : label,
                style: TextStyle(color: colors.textPrimary, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: colors.textMuted),
          ],
        ),
      ),
    );
  }

  // ---------------- Вкладка: Стафф (только язык) ----------------

  Widget _buildStaffTab(AppPalette colors) {
    return _glassWrap(
      colors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user_rounded, size: 16, color: colors.accentPrimary),
              const SizedBox(width: 6),
              Text(
                AppLocalizations.t('admin.community.staff_only_section'),
                style: TextStyle(color: colors.accentPrimary, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.t('admin.community.staff_only_hint'),
            style: TextStyle(color: colors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          _fieldLabel(colors, AppLocalizations.t('admin.community.field_language')),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _language,
            dropdownColor: colors.bgGradient.last,
            style: TextStyle(color: colors.textPrimary),
            items: _availableLanguages
                .map((lang) => DropdownMenuItem(value: lang, child: Text(lang.toUpperCase())))
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => _language = val);
            },
          ),
        ],
      ),
    );
  }

  // ---------------- Общие вспомогательные виджеты ----------------

  Widget _glassWrap(AppPalette colors, {required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: colors.glassCard(radius: 24),
          padding: const EdgeInsets.all(20),
          child: child,
        ),
      ),
    );
  }

  Widget _fieldLabel(AppPalette colors, String text) {
    return Text(
      text,
      style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildSubmitButton(AppPalette colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.accentPrimary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          icon: const Icon(Icons.save_rounded, size: 20),
          label: Text(
            AppLocalizations.t('common.save'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          onPressed: _saveChanges,
        ),
      ),
    );
  }
}