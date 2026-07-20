import 'dart:ui';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cross_file/cross_file.dart';
import '../../../core/api/repositories/search.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/text_editor.dart';
import '../../../core/api/repositories/altacm.dart';
import '../../../core/api/repositories/links.dart';
import '../../../core/api/repositories/communities.dart';
import '../../../core/api/repositories/users.dart';
import '../../../core/api/repositories/theme_editor.dart';

import '../../../core/storage.dart';
import '../../../core/api/objects/args/roles.dart';

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

  final _altAcmRepo = AltACMRepository();
  final _searchRepo = SearchRepository();
  final _communitiesRepo = CommunitiesRepository();
  final _usersRepo = UsersRepository();

  late TextEditingController _nameController;
  late TextEditingController _taglineController;
  late TextEditingController _aminoIdController;
  late TextEditingController _descriptionController;
  late TextEditingController _guidelinesController;
  late TextEditingController _welcomeMessageController;

  XFile? _selectedIconFile;
  String? _currentIconUrl;

  XFile? _selectedCoverFile;
  String? _currentCoverUrl;

  bool _welcomeMessageEnabled = false;

  int _joinType = 0;
  bool _hidden = false;

  late bool _isStaff;
  late String _language;
  List<String> _availableLanguages = ['en'];
  bool _languagesLoading = false;

  bool get _canTransferAgent => _isStaff || Storage.role == RoleTypes.roleAgent;

  List<dynamic> _descriptionMediaList = [];
  List<dynamic> _guidelineMediaList = [];
  bool _guidelineLoading = false;

  bool _themeEditingEnabled = false;
  bool _themeCompressionEnabled = true;

  String? _themePackUrl;
  int _serverThemeRevision = 0;
  ThemeEditor? _themeEditor;
  bool _themeLoading = false;
  String? _themeLoadError;

  XFile? _selectedThemeBackgroundFile;
  XFile? _selectedThemeTitlebarBgFile;
  XFile? _selectedThemeTitlebarFile;

  bool _removeThemeBackground = false;
  bool _removeThemeTitlebarBg = false;
  bool _removeThemeTitlebar = false;

  String _themeColorHex = '';
  static const List<String> _palette = [
    '#780000', '#C1121F', '#E63946', '#F77F00', '#FCBF49',
    '#2A9D8F', '#43AA8B', '#90BE6D', '#4D908E', '#277DA1',
    '#118AB2', '#0077B6', '#3A0CA3', '#7209B7', '#B5179E',
    '#F72585', '#FF6B6B', '#6D6875', '#3D405B', '#264653',
    '#1B263B', '#000000', '#2B2D42', '#5F0F40',
  ];

  bool _isLoading = false;

  bool _dataChanged = false;

  final _userSearchController = TextEditingController();
  List<dynamic> _communityUsers = [];
  bool _usersLoading = false;
  String _usersQuery = '';

  List<Tab> get _tabs => [
        Tab(text: AppLocalizations.t('admin.community.tab_general'), icon: const Icon(Icons.tune_rounded, size: 20)),
        Tab(text: AppLocalizations.t('admin.community.tab_media'), icon: const Icon(Icons.image_rounded, size: 20)),
        Tab(text: AppLocalizations.t('admin.community.tab_content'), icon: const Icon(Icons.article_rounded, size: 20)),
        Tab(text: AppLocalizations.t('admin.community.tab_users'), icon: const Icon(Icons.people_alt_rounded, size: 20)),
      ];

  int get _ndcId {
    final raw = widget.communityData?['ndcId'] ?? widget.communityData?['id'];
    if (raw == null) throw Exception("ndcId / id not found in communityData");
    return int.parse(raw.toString());
  }

  @override
  void initState() {
    super.initState();

    _isStaff = RoleTypes.isStaffRole(Storage.role);
    _tabController = TabController(length: 4, vsync: this);

    final data = widget.communityData;

    _nameController = TextEditingController(text: data?['name'] ?? '');
    _taglineController = TextEditingController(text: data?['tagline'] ?? '');
    _aminoIdController = TextEditingController(text: data?['endpoint'] ?? data?['aminoId'] ?? '');
    _descriptionController = TextEditingController(text: data?['content'] ?? data?['description'] ?? '');
    _guidelinesController = TextEditingController(text: data?['guidelines'] ?? '');

    _descriptionMediaList = List<dynamic>.from(data?['mediaList'] ?? []);

    final themePack = (data?['themePack'] as Map?)?.cast<String, dynamic>() ?? {};
    _themeColorHex = (themePack['themeColor'] ?? data?['themeColor'] ?? '').toString();
    _themePackUrl = themePack['themePackUrl'];
    _serverThemeRevision = int.tryParse('${themePack['themePackRevision'] ?? 0}') ?? 0;

    final advanced = (data?['advancedSettings'] as Map?)?.cast<String, dynamic>() ?? {};
    final configuration = (data?['configuration'] as Map?)?.cast<String, dynamic>() ?? {};
    _welcomeMessageController = TextEditingController(
      text: advanced['welcomeMessageText'] ?? configuration['welcomeMessage'] ?? '',
    );
    _welcomeMessageEnabled =
        (advanced['welcomeMessageEnabled'] ?? configuration['welcomeMessageEnabled']) == true;

    _currentIconUrl = data?['icon'];
    final promo = data?['promotionalMediaList'];
    if (promo is List && promo.isNotEmpty && promo.first is List && (promo.first as List).length > 1) {
      _currentCoverUrl = (promo.first as List)[1]?.toString();
    }
    _currentCoverUrl ??= data?['coverUrl'] ?? data?['cover'];

    final rawJoin = data?['joinType'] ?? configuration['joinType'] ?? 0;
    _joinType = rawJoin is int ? rawJoin : int.tryParse('$rawJoin') ?? 0;
    _hidden = (configuration['hidden'] ?? data?['hidden']) == true;

    final lang = (data?['primaryLanguage'] ?? data?['lang'] ?? data?['language'])?.toString();
    _language = (lang == null || lang.isEmpty) ? 'en' : lang;

    _loadGuideline();
    if (_isStaff) _loadLanguages();
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
    _userSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadLanguages() async {
    setState(() => _languagesLoading = true);
    try {
      final res = await _searchRepo.getAvailableLanguages();
      final langs = List<String>.from(res['supportedLanguages'] ?? []);
      if (!mounted) return;
      setState(() {
        if (langs.isNotEmpty) _availableLanguages = langs;
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _languagesLoading = false);
    }
  }

  Future<void> _loadGuideline() async {
    setState(() => _guidelineLoading = true);
    try {
      final res = await _communitiesRepo.getCommunityGuideline(_ndcId);
      final g = (res['communityGuideline'] as Map?)?.cast<String, dynamic>() ?? {};
      if (!mounted) return;
      setState(() {
        final content = (g['content'] ?? '').toString();
        if (content.isNotEmpty || _guidelinesController.text.isEmpty) {
          _guidelinesController.text = content;
        }
        _guidelineMediaList = List<dynamic>.from(g['mediaList'] ?? []);
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _guidelineLoading = false);
    }
  }

  Future<void> _pickImageInto(void Function(XFile) assign, {double? maxWidth, double? maxHeight}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth ?? 1600,
        maxHeight: maxHeight,
      );
      if (image != null) setState(() => assign(image));
    } catch (e) {
      if (mounted) AppSnackbar.show(context, e.toString(), type: SnackType.error);
    }
  }

  Future<void> _pickIcon() => _pickImageInto((f) => _selectedIconFile = f, maxWidth: 512, maxHeight: 512);
  Future<void> _pickCover() => _pickImageInto((f) => _selectedCoverFile = f);

  Future<void> _pickThemeBackground() => _pickImageInto((f) {
        _selectedThemeBackgroundFile = f;
        _removeThemeBackground = false;
      });
  Future<void> _pickThemeTitlebarBg() => _pickImageInto((f) {
        _selectedThemeTitlebarBgFile = f;
        _removeThemeTitlebarBg = false;
      });
  Future<void> _pickThemeTitlebar() => _pickImageInto((f) {
        _selectedThemeTitlebarFile = f;
        _removeThemeTitlebar = false;
      });

  Future<void> _loadExistingThemePack() async {
    if (_themeEditor != null || _themeLoading) return;
    final url = _themePackUrl;
    if (url == null || url.isEmpty) {
      setState(() => _themeEditor = ThemeEditor.newTheme());
      return;
    }

    setState(() {
      _themeLoading = true;
      _themeLoadError = null;
    });

    try {
      final bytes = await _downloadBytes(url);
      final editor = ThemeEditor.fromBytes(bytes);
      if (_serverThemeRevision > editor.revision) {
        editor.revision = _serverThemeRevision;
      }
      if (!mounted) return;
      setState(() => _themeEditor = editor);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _themeEditor = ThemeEditor.newTheme();
        if (_serverThemeRevision > 0) {
          _themeEditor!.revision = _serverThemeRevision;
        }
        _themeLoadError = e.toString();
      });
    } finally {
      if (mounted) setState(() => _themeLoading = false);
    }
  }

  Future<Uint8List> _downloadBytes(String url) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode != 200) {
        throw Exception('Theme pack download failed: HTTP ${response.statusCode}');
      }
      final builder = BytesBuilder(copy: false);
      await for (final chunk in response) {
        builder.add(chunk);
      }
      return builder.takeBytes();
    } finally {
      client.close();
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final ndcId = _ndcId;
      final linksRepo = LinksRepository();

      String? uploadedIconUrl;
      if (_selectedIconFile != null) {
        final res = await linksRepo.uploadMedia(file: _selectedIconFile!);
        uploadedIconUrl = res['mediaValue'];
      }

      String? uploadedCoverUrl;
      if (_selectedCoverFile != null) {
        final res = await linksRepo.uploadMedia(file: _selectedCoverFile!);
        uploadedCoverUrl = res['mediaValue'];
      }

      String? themeUrl;
      int? themeRevision;
      final hasNewThemeImages = _selectedThemeBackgroundFile != null ||
          _selectedThemeTitlebarBgFile != null ||
          _selectedThemeTitlebarFile != null;
      final hasRemovals = _removeThemeBackground || _removeThemeTitlebarBg || _removeThemeTitlebar;
      final themeColor = _themeColorHex.isEmpty ? null : _themeColorHex;

      if (_themeEditingEnabled && (hasNewThemeImages || hasRemovals || themeColor != null)) {
        if (_themeEditor == null) {
          await _loadExistingThemePack();
        }
        final themeEditor = _themeEditor ?? ThemeEditor.newTheme();

        if (_removeThemeBackground && _selectedThemeBackgroundFile == null) {
          themeEditor.removeImage('background');
        }
        if (_removeThemeTitlebarBg && _selectedThemeTitlebarBgFile == null) {
          themeEditor.removeImage('titlebarbg');
        }
        if (_removeThemeTitlebar && _selectedThemeTitlebarFile == null) {
          themeEditor.removeImage('titlebar');
        }

        if (_selectedThemeBackgroundFile != null) {
          themeEditor.injectImage(
            forWhat: 'background',
            newImageData: await _selectedThemeBackgroundFile!.readAsBytes(),
            compress: _themeCompressionEnabled,
          );
        }
        if (_selectedThemeTitlebarBgFile != null) {
          themeEditor.injectImage(
            forWhat: 'titlebarbg',
            newImageData: await _selectedThemeTitlebarBgFile!.readAsBytes(),
            compress: _themeCompressionEnabled,
          );
        }
        if (_selectedThemeTitlebarFile != null) {
          themeEditor.injectImage(
            forWhat: 'titlebar',
            newImageData: await _selectedThemeTitlebarFile!.readAsBytes(),
            compress: _themeCompressionEnabled,
          );
        }
        if (themeColor != null) {
          themeEditor.setThemeColor(themeColor);
        }

        themeEditor.incrementRevision();
        final zipBytes = themeEditor.rebuild();

        final uploadRes = await linksRepo.uploadThemeArchive(zipBytes: zipBytes, ndcId: ndcId);
        themeUrl = uploadRes['mediaValue'];
        themeRevision = themeEditor.revision;
      }

      final descriptionText = _descriptionController.text.trim();
      final guidelineText = _guidelinesController.text.trim();

      await _altAcmRepo.editCommunity(
        ndcId,
        name: _nameController.text.trim(),
        aminoId: _aminoIdController.text.trim(),
        tagline: _taglineController.text.trim(),
        description: descriptionText,
        descriptionMediaList: AminoTextEditor.pruneMediaList(descriptionText, _descriptionMediaList),
        guidelines: guidelineText,
        guidelineMediaList: AminoTextEditor.pruneMediaList(guidelineText, _guidelineMediaList),
        icon: uploadedIconUrl,
        coverUrl: uploadedCoverUrl,
        themeUrl: themeUrl,
        themeColor: themeColor,
        themeRevision: themeRevision,
        welcomeMessage: _emptyToNull(_welcomeMessageController.text),
        welcomeMessageEnabled: _welcomeMessageEnabled,
        joinType: _joinType,
        hidden: _hidden,
        language: _isStaff ? _language : null,
      );

      if (!mounted) return;

      _dataChanged = true;

      AppSnackbar.show(
        context,
        AppLocalizations.t('admin.community.save_success'),
        type: SnackType.success,
      );

      context.pop(true);
    } catch (e, stackTrace) {
      print('Что случилось: $e');
      print('Где именно: $stackTrace');
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

  Future<void> _searchCommunityUsers(String q) async {
    _usersQuery = q;
    if (q.trim().isEmpty) {
      setState(() => _communityUsers = []);
      return;
    }

    setState(() => _usersLoading = true);
    try {
      final res = await _searchRepo.searchUser(ndcId: _ndcId, q: q);
      if (!mounted || _usersQuery != q) return;
      setState(() {
        _communityUsers = res['userProfileList'] ?? [];
        _usersLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _usersLoading = false);
      AppSnackbar.show(context, e.toString(), type: SnackType.error);
    }
  }

  Future<void> _changeUserRole(Map<String, dynamic> user, int? newRole) async {
    final previousRole = user['role'];
    setState(() => user['role'] = newRole ?? RoleTypes.roleUser);
    try {
      if (newRole == null || newRole == RoleTypes.roleUser) {
        await _altAcmRepo.unpromoteUser(user['uid'], _ndcId);
      } else {
        await _altAcmRepo.promoteUser(user['uid'], _ndcId, newRole);
      }
      if (!mounted) return;
      _dataChanged = true;
      AppSnackbar.show(context, AppLocalizations.t('admin.community.role_updated'), type: SnackType.success);
    } catch (e) {
      if (!mounted) return;
      setState(() => user['role'] = previousRole);
      AppSnackbar.show(context, e.toString(), type: SnackType.error);
    }
  }

  Future<bool?> _confirmDialog({
    required AppPalette colors,
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: colors.glassFillStrong,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(title, style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          content: Text(message, style: TextStyle(color: colors.textMuted, fontSize: 14)),
          actions: [
            TextButton(
              onPressed: () => context.pop(false),
              child: Text(AppLocalizations.t('common.cancel'), style: TextStyle(color: colors.textMuted)),
            ),
            TextButton(
              onPressed: () => context.pop(true),
              child: Text(confirmLabel, style: TextStyle(color: confirmColor, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _transferAgent(Map<String, dynamic> user) async {
    final colors = AppColors.of(context);
    final confirmed = await _confirmDialog(
      colors: colors,
      title: AppLocalizations.t('admin.community.transfer_agent_title'),
      message: AppLocalizations.t('admin.community.transfer_agent_message'),
      confirmLabel: AppLocalizations.t('admin.community.transfer_agent_confirm'),
      confirmColor: colors.error,
    );
    if (confirmed != true) return;

    try {
      await _altAcmRepo.promoteUser(user['uid'], _ndcId, RoleTypes.roleAgent);
      if (!mounted) return;
      setState(() => user['role'] = RoleTypes.roleAgent);
      _dataChanged = true;
      AppSnackbar.show(context, AppLocalizations.t('admin.community.transfer_agent_success'), type: SnackType.success);
      _searchCommunityUsers(_usersQuery);
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(context, e.toString(), type: SnackType.error);
    }
  }

  /// Диалог с полем ввода причины. Возвращает введённый текст
  /// (может быть пустым) или null, если отменили.
  Future<String?> _reasonDialog({
    required AppPalette colors,
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: colors.glassFillStrong,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(title, style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message, style: TextStyle(color: colors.textMuted, fontSize: 14)),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                maxLines: 2,
                style: TextStyle(color: colors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: AppLocalizations.t('admin.community.ban_reason_hint'),
                  hintStyle: TextStyle(color: colors.textMuted, fontSize: 13),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: Text(AppLocalizations.t('common.cancel'), style: TextStyle(color: colors.textMuted)),
            ),
            TextButton(
              onPressed: () => context.pop(controller.text),
              child: Text(confirmLabel, style: TextStyle(color: confirmColor, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

Future<void> _banUser(Map<String, dynamic> user) async {
  final colors = AppColors.of(context);
  final reason = await _reasonDialog(
    colors: colors,
    title: AppLocalizations.t('admin.community.ban_dialog_title'),
    message: AppLocalizations.t('admin.community.ban_dialog_message'),
    confirmLabel: AppLocalizations.t('admin.community.ban'),
    confirmColor: colors.error,
  );
  if (reason == null) return;

  try {
    await _usersRepo.banUser(
      userId: user['uid'] as String?,
      ndcId: _ndcId,
      reason: reason,
    );
    if (!mounted) return;
    setState(() => user['membershipStatus'] = 3);
    _dataChanged = true;
    AppSnackbar.show(context, AppLocalizations.t('admin.community.user_banned'), type: SnackType.success);
  } catch (e) {
    if (!mounted) return;
    AppSnackbar.show(context, e.toString(), type: SnackType.error);
  }
}

Future<void> _unbanUser(Map<String, dynamic> user) async {
  final colors = AppColors.of(context);
  final reason = await _reasonDialog(
    colors: colors,
    title: AppLocalizations.t('admin.community.unban_dialog_title'),
    message: AppLocalizations.t('admin.community.unban_dialog_message'),
    confirmLabel: AppLocalizations.t('admin.community.unban'),
    confirmColor: colors.accentPrimary,
  );
  if (reason == null) return;

  try {
    await _usersRepo.unbanUser(
      userId: user['uid'] as String?,
      ndcId: _ndcId,
      reason: reason,
    );
    if (!mounted) return;
    setState(() => user['membershipStatus'] = 0);
    _dataChanged = true;
    AppSnackbar.show(context, AppLocalizations.t('admin.community.user_unbanned'), type: SnackType.success);
  } catch (e) {
    if (!mounted) return;
    AppSnackbar.show(context, e.toString(), type: SnackType.error);
  }
}

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.pop(_dataChanged);
      },
      child: Scaffold(
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
                              _tabScroll(_buildUsersTab(colors)),
                            ],
                          ),
                        ),
                ),
                if (!_isLoading) _buildSubmitButton(colors),
              ],
            ),
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
            onPressed: () => context.pop(_dataChanged),
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
        if (_isStaff) ...[
          const SizedBox(height: 16),
          _buildStaffSection(colors),
        ],
      ],
    );
  }

  Widget _buildStaffSection(AppPalette colors) {
    final languageItems = <String>[
      if (!_availableLanguages.contains(_language)) _language,
      ..._availableLanguages,
    ];

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
          if (_languagesLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: colors.accentPrimary),
                ),
              ),
            )
          else
            DropdownButtonFormField<String>(
              initialValue: _language,
              dropdownColor: colors.bgGradient.last,
              style: TextStyle(color: colors.textPrimary),
              items: languageItems
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
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: colors.textMuted.withOpacity(0.2),
              image: imageProvider != null
                  ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
                  : null,
            ),
            child: imageProvider == null
                ? Icon(Icons.add_photo_alternate_rounded, size: 40, color: colors.textSecondary)
                : null,
          ),
          Positioned(
            right: -4,
            bottom: -4,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colors.accentPrimary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.edit_rounded, size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaTab(AppPalette colors) {
    return Column(
      children: [
        _buildCoverSection(colors),
        const SizedBox(height: 16),
        _buildThemeSection(colors),
      ],
    );
  }

  Widget _buildCoverSection(AppPalette colors) {
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
          Center(
            child: GestureDetector(
              onTap: _pickCover,
              child: Container(
                width: 160,
                height: 284,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: colors.textMuted.withOpacity(0.15),
                  border: Border.all(color: colors.textMuted.withOpacity(0.3)),
                  image: imageProvider != null
                      ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
                      : null,
                ),
                child: imageProvider == null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_photo_alternate_rounded, size: 32, color: colors.textSecondary),
                            const SizedBox(height: 8),
                            Text(
                              AppLocalizations.t('admin.community.field_cover_hint'),
                              textAlign: TextAlign.center,
                              style: TextStyle(color: colors.textMuted, fontSize: 11),
                            ),
                          ],
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider? _themeSlotImage(XFile? picked, Uint8List? packBytes, bool removed) {
    if (picked != null) return FileImage(File(picked.path));
    if (removed) return null;
    if (packBytes != null && packBytes.isNotEmpty) return MemoryImage(packBytes);
    return null;
  }

  Color _parsedThemeColor(AppPalette colors) {
    final hex = RegExp(r'^#([0-9a-fA-F]{6})$');
    if (hex.hasMatch(_themeColorHex)) {
      return Color(int.parse('FF${_themeColorHex.substring(1)}', radix: 16));
    }
    return colors.accentPrimary;
  }

  Widget _buildThemeSection(AppPalette colors) {
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
                onChanged: (val) {
                  setState(() => _themeEditingEnabled = val);
                  if (val) _loadExistingThemePack();
                },
              ),
            ],
          ),
          if (_themeEditingEnabled) ...[
            const SizedBox(height: 16),
            if (_themeLoading)
              SizedBox(
                height: 260,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: colors.accentPrimary),
                      const SizedBox(height: 12),
                      Text(
                        AppLocalizations.t('admin.community.theme_loading'),
                        style: TextStyle(color: colors.textMuted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              if (_themeLoadError != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.orange.withOpacity(0.12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppLocalizations.t('admin.community.theme_load_failed'),
                          style: TextStyle(color: colors.textSecondary, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              _buildThemePreview(colors),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  AppLocalizations.t('admin.community.theme_preview_hint'),
                  style: TextStyle(color: colors.textMuted, fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel(colors, AppLocalizations.t('admin.community.field_theme_compress')),
                        const SizedBox(height: 2),
                        Text(
                          AppLocalizations.t('admin.community.field_theme_compress_hint'),
                          style: TextStyle(color: colors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _themeCompressionEnabled,
                    activeColor: colors.accentPrimary,
                    onChanged: (val) => setState(() => _themeCompressionEnabled = val),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _fieldLabel(colors, AppLocalizations.t('admin.community.field_theme_color')),
              const SizedBox(height: 10),
              _buildColorPalette(colors),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.history_rounded, size: 14, color: colors.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    '${AppLocalizations.t('admin.community.theme_revision')}: '
                    '${_themeEditor?.revision ?? _serverThemeRevision} → '
                    '${(_themeEditor?.revision ?? _serverThemeRevision) + 1}',
                    style: TextStyle(color: colors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildColorPalette(AppPalette colors) {
    final items = <String>[
      if (_themeColorHex.isNotEmpty && !_palette.contains(_themeColorHex.toUpperCase()))
        _themeColorHex.toUpperCase(),
      ..._palette,
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items.map((hex) {
        final color = Color(int.parse('FF${hex.substring(1)}', radix: 16));
        final selected = _themeColorHex.toUpperCase() == hex.toUpperCase();

        return GestureDetector(
          onTap: () => setState(() => _themeColorHex = hex),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? Colors.white : Colors.white.withOpacity(0.15),
                width: selected ? 2.5 : 1,
              ),
              boxShadow: selected
                  ? [BoxShadow(color: color.withOpacity(0.6), blurRadius: 8, spreadRadius: 1)]
                  : null,
            ),
            child: selected
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildThemePreview(AppPalette colors) {
    final themeColor = _parsedThemeColor(colors);

    final sidebarBgImage = _themeSlotImage(
      _selectedThemeBackgroundFile,
      _themeEditor?.backgroundBytes,
      _removeThemeBackground,
    );
    final mainBgImage = _themeSlotImage(
      _selectedThemeTitlebarBgFile,
      _themeEditor?.titlebarBackgroundBytes,
      _removeThemeTitlebarBg,
    );
    final sidebarLogoImage = _themeSlotImage(
      _selectedThemeTitlebarFile,
      _themeEditor?.titlebarBytes,
      _removeThemeTitlebar,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 300,
        decoration: BoxDecoration(
          border: Border.all(color: colors.textMuted.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 110,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  GestureDetector(
                    onTap: _pickThemeBackground,
                    child: Container(
                      color: const Color(0xFF1A1A2E),
                      child: sidebarBgImage != null
                          ? Image(image: sidebarBgImage, fit: BoxFit.cover)
                          : null,
                    ),
                  ),
                  IgnorePointer(
                    child: Container(color: Colors.black.withOpacity(0.25)),
                  ),
                  Column(
                    children: [
                      GestureDetector(
                        onTap: _pickThemeTitlebar,
                        child: SizedBox(
                          height: 56,
                          width: double.infinity,
                          child: Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: sidebarLogoImage != null
                                    ? Image(image: sidebarLogoImage, fit: BoxFit.contain, width: double.infinity)
                                    : _emptySlotHint(
                                        icon: Icons.title_rounded,
                                        label: AppLocalizations.t('admin.community.field_theme_sidebar_logo'),
                                      ),
                              ),
                              if (sidebarLogoImage != null)
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: _slotDeleteChip(
                                    onTap: () => setState(() {
                                      _selectedThemeTitlebarFile = null;
                                      _removeThemeTitlebar = true;
                                    }),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._fakeSidebarItems(),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _slotEditChip(
                            onTap: _pickThemeBackground,
                            label: AppLocalizations.t('admin.community.field_theme_sidebar_bg'),
                          ),
                          if (sidebarBgImage != null) ...[
                            const SizedBox(width: 4),
                            _slotDeleteChip(
                              onTap: () => setState(() {
                                _selectedThemeBackgroundFile = null;
                                _removeThemeBackground = true;
                              }),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: _pickThemeTitlebarBg,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: const Color(0xFF16213E),
                      child: mainBgImage != null
                          ? Image(image: mainBgImage, fit: BoxFit.cover)
                          : Center(
                              child: _emptySlotHint(
                                icon: Icons.wallpaper_rounded,
                                label: AppLocalizations.t('admin.community.field_theme_background'),
                              ),
                            ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: IgnorePointer(
                        child: Container(
                          height: 140,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                themeColor.withOpacity(0.0),
                                themeColor.withOpacity(0.55),
                                themeColor,
                              ],
                            ),
                          ),
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                          alignment: Alignment.bottomLeft,
                          child: Text(
                            _nameController.text.isEmpty ? 'Community' : _nameController.text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _slotEditChip(
                              onTap: _pickThemeTitlebarBg,
                              label: AppLocalizations.t('admin.community.field_theme_background'),
                            ),
                            if (mainBgImage != null) ...[
                              const SizedBox(width: 4),
                              _slotDeleteChip(
                                onTap: () => setState(() {
                                  _selectedThemeTitlebarBgFile = null;
                                  _removeThemeTitlebarBg = true;
                                }),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _fakeSidebarItems() {
    return List.generate(3, (i) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: IgnorePointer(
          child: Container(
            height: 10,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.35),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
      );
    });
  }

  Widget _emptySlotHint({required IconData icon, required String label}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.7), size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _slotEditChip({required VoidCallback onTap, required String label}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.55),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.edit_rounded, color: Colors.white, size: 12),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 80),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _slotDeleteChip({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.75),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
      ),
    );
  }

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
              AminoTextEditor(
                controller: _descriptionController,
                mediaList: _descriptionMediaList,
                hint: AppLocalizations.t('admin.community.field_description_hint'),
                minLines: 4,
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
              _fieldLabel(colors, AppLocalizations.t('admin.community.field_guidelines')),
              const SizedBox(height: 8),
              if (_guidelineLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator(color: colors.accentPrimary)),
                )
              else
                AminoTextEditor(
                  controller: _guidelinesController,
                  mediaList: _guidelineMediaList,
                  hint: AppLocalizations.t('admin.community.field_guidelines_hint'),
                  minLines: 6,
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

  Widget _buildUsersTab(AppPalette colors) {
    return Column(
      children: [
        _glassWrap(
          colors,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fieldLabel(colors, AppLocalizations.t('admin.community.field_search_users')),
              const SizedBox(height: 8),
              TextField(
                controller: _userSearchController,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: AppLocalizations.t('admin.community.search_users_hint'),
                  hintStyle: TextStyle(color: colors.textMuted),
                  prefixIcon: Icon(Icons.search, color: colors.textMuted),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => _searchCommunityUsers(_userSearchController.text),
                  ),
                ),
                onSubmitted: _searchCommunityUsers,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_usersLoading)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Center(child: CircularProgressIndicator(color: colors.accentPrimary)),
          )
        else if (_communityUsers.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Center(
              child: Text(
                AppLocalizations.t('admin.community.search_users_empty'),
                style: TextStyle(color: colors.textMuted),
              ),
            ),
          )
        else
          ..._communityUsers.map((u) => _buildUserRow(colors, u as Map<String, dynamic>)),
      ],
    );
  }

  Widget _buildUserRow(AppPalette colors, Map<String, dynamic> user) {
    final rawRole = user['role'];
    final role = rawRole is int ? rawRole : int.tryParse('$rawRole') ?? RoleTypes.roleUser;
    final isOwner = role == RoleTypes.roleAgent;
    final isTargetStaff = RoleTypes.isStaffRole(role);
    final isBanned = user['status'] == 9;

    final roleLabels = <int, String>{
      RoleTypes.roleUser: AppLocalizations.t('admin.community.role_member'),
      RoleTypes.roleCurator: AppLocalizations.t('admin.community.role_curator'),
      RoleTypes.roleLeader: AppLocalizations.t('admin.community.role_leader'),
    };
    if (!isOwner && !isTargetStaff && !roleLabels.containsKey(role)) {
      roleLabels[role] = '${AppLocalizations.t('admin.community.role_unknown')} ($role)';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _glassWrap(
        colors,
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundImage: user['icon'] != null ? NetworkImage(user['icon']) : null,
              child: user['icon'] == null ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['nickname'] ?? '',
                    style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (isTargetStaff)
                    Text(
                      AppLocalizations.t('admin.community.role_staff'),
                      style: TextStyle(color: colors.accentPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                    )
                  else if (isOwner)
                    Text(
                      AppLocalizations.t('admin.community.role_owner'),
                      style: TextStyle(color: colors.accentPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                    )
                  else
                    DropdownButton<int>(
                      value: role,
                      isDense: true,
                      dropdownColor: colors.bgGradient.last,
                      underline: const SizedBox.shrink(),
                      style: TextStyle(color: colors.textSecondary, fontSize: 13),
                      items: roleLabels.entries
                          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                          .toList(),
                      onChanged: (val) => _changeUserRole(user, val),
                    ),
                ],
              ),
            ),
            if (!isOwner && !isTargetStaff) ...[
              if (_canTransferAgent)
                IconButton(
                  tooltip: AppLocalizations.t('admin.community.transfer_agent_tooltip'),
                  icon: Icon(Icons.workspace_premium_rounded, color: colors.textMuted),
                  onPressed: () => _transferAgent(user),
                ),
              IconButton(
                icon: Icon(
                  isBanned ? Icons.lock_open_rounded : Icons.block_rounded,
                  color: isBanned ? colors.accentPrimary : colors.error,
                ),
                onPressed: () => isBanned ? _unbanUser(user) : _banUser(user),
              ),
            ],
          ],
        ),
      ),
    );
  }

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