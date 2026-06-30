import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/api/objects/args/roles.dart';
import '../../core/api/repositories/altacm.dart';
import '../../core/api/repositories/search.dart';
import '../../core/api/repositories/communities.dart';
import '../../core/storage.dart';
import '../../core/widgets/glass_dropdown.dart';

class AltAcmMainScreen extends StatefulWidget {
  const AltAcmMainScreen({super.key});

  @override
  State<AltAcmMainScreen> createState() => _AltAcmMainScreenState();
}

class _AltAcmMainScreenState extends State<AltAcmMainScreen>
    with SingleTickerProviderStateMixin {
  late final bool _isStaff = RoleTypes.isStaffRole(Storage.role);
  TabController? _tabController; // Сделали nullable, так как для не-стаффа он не нужен
  final _altAcm = AltACMRepository();
  final _searchRepo = SearchRepository();
  final _comRepo = CommunitiesRepository();

  List<Map<String, dynamic>> _myCommunities = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _loadingMy = true;
  bool _loadingSearch = false;
  String _query = '';

  List<String> _languages = [];
  String? _selectedLang;

  @override
  void initState() {
    super.initState();
    _loadMyCommunities();
    
    // Инициализируем табы и загружаем языки только если это персонал
    if (_isStaff) {
      _tabController = TabController(length: 2, vsync: this);
      _loadLanguages();
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadMyCommunities() async {
    setState(() => _loadingMy = true);
    try {
      final res = await _altAcm.getUserManagedCommunities(Storage.userId ?? '');
      final ids = List<int>.from(res['communityIdList'] ?? []);

      final communities = <Map<String, dynamic>>[];
      for (final ndcId in ids) {
        final info = await _comRepo.getCommunityInfo(ndcId);
        if (info['community'] != null) communities.add(info['community']);
      }

      if (!mounted) return;
      setState(() {
        _myCommunities = communities;
        _loadingMy = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMy = false);
    }
  }

  Future<void> _loadLanguages() async {
    try {
      final res = await _searchRepo.getAvailableLanguages();
      final langs = List<String>.from(res['supportedLanguages'] ?? []);
      if (!mounted) return;
      setState(() {
        _languages = langs;
        _selectedLang = langs.isNotEmpty ? langs.first : null;
      });
    } catch (_) {}
  }

  Future<void> _runSearch(String q) async {
    if (!_isStaff) return;
    _query = q;
    if (q.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _loadingSearch = true);
    try {
      final res = await _searchRepo.searchCommunity(
        lang: _selectedLang,
        q: q,
        start: 0,
        size: 20,
      );
      if (!mounted || _query != q) return;
      setState(() {
        _searchResults = List<Map<String, dynamic>>.from(res['communityList'] ?? []);
        _loadingSearch = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingSearch = false);
    }
  }

  void _onLangChanged(String lang) {
    setState(() => _selectedLang = lang);
    if (_query.isNotEmpty) _runSearch(_query);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: colors.accentPrimary,
        onPressed: () async {
          final refresh = await context.push<bool>('/altacm/community/create');
          if (refresh == true) _loadMyCommunities();
        },
        icon: const Icon(Icons.add),
        label: Text(
          AppLocalizations.t('admin.community.create'), 
          style: TextStyle(color: colors.textPrimary, fontSize: 13),
        ),
      ),
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
              _buildAppBar(context, colors, AppLocalizations.t('drawer.alt_acm')),
              // ИСПРАВЛЕНО: Показываем TabBar только для стаффа
              if (_isStaff) _buildTabBar(colors),
              Expanded(
                // ИСПРАВЛЕНО: Если не стафф, сразу отдаем вкладку "Мои сообщества" без TabBoxView
                child: _isStaff
                    ? TabBarView(
                        controller: _tabController,
                        children: [
                          _buildMyCommunitiesTab(colors),
                          _buildSearchTab(colors),
                        ],
                      )
                    : _buildMyCommunitiesTab(colors),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, AppPalette colors, String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: colors.textPrimary, size: 20),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(AppPalette colors) {
    return TabBar(
      controller: _tabController,
      indicatorColor: colors.accentPrimary,
      labelColor: colors.textPrimary,
      unselectedLabelColor: colors.textMuted,
      tabs: [
        Tab(text: AppLocalizations.t('admin.community.my')),
        Tab(text: AppLocalizations.t('admin.community.search')),
      ],
    );
  }

  Widget _buildMyCommunitiesTab(AppPalette colors) {
    if (_loadingMy) {
      return Center(child: CircularProgressIndicator(color: colors.accentPrimary));
    }

    return RefreshIndicator(
      onRefresh: _loadMyCommunities,
      child: _myCommunities.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Center(
                    child: Text(
                      AppLocalizations.t('admin.community.empty'),
                      style: TextStyle(color: colors.textMuted),
                    ),
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _myCommunities.length,
              itemBuilder: (_, i) => _buildCommunityCard(colors, _myCommunities[i]),
            ),
    );
  }

  Widget _buildSearchTab(AppPalette colors) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: _runSearch,
                  style: TextStyle(color: colors.textPrimary),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.t('admin.community.search_hint'),
                    hintStyle: TextStyle(color: colors.textMuted),
                    prefixIcon: Icon(Icons.search, color: colors.textMuted),
                    filled: true,
                    fillColor: colors.accentPrimary.withOpacity(0.06),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              if (_languages.isNotEmpty) ...[
                const SizedBox(width: 8),
                GlassDropdown<String>(
                  icon: Icons.language,
                  value: _selectedLang ?? 'en',
                  items: _languages,
                  itemLabel: (l) => l.toUpperCase(),
                  onChanged: (l) {
                    if (l != null) _onLangChanged(l);
                  },
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: _loadingSearch
              ? Center(child: CircularProgressIndicator(color: colors.accentPrimary))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: _searchResults.length,
                  itemBuilder: (_, i) => _buildCommunityCard(colors, _searchResults[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildCommunityCard(AppPalette colors, Map<String, dynamic> community) {
    final ndcId = community['ndcId'];
    final name = community['name'] ?? '';
    final icon = community['icon'] as String?;
    final members = community['membersCount'] ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () async {
          // Если из экрана деталей вернулся true (сообщество удалили), обновляем список
          final refresh = await context.push<bool>('/altacm/community/$ndcId');
          if (refresh == true) _loadMyCommunities();
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: colors.glassCard(radius: 18),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: icon != null
                        ? Image.network(icon, width: 52, height: 52, fit: BoxFit.cover)
                        : Container(
                            width: 52,
                            height: 52,
                            color: colors.accentPrimary.withOpacity(0.12),
                            child: Icon(Icons.groups_outlined, color: colors.accentPrimary),
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(color: colors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$members ${AppLocalizations.t('admin.community.members')}',
                          style: TextStyle(color: colors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: colors.textMuted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}