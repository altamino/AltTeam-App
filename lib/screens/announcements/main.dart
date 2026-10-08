import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/objects/args/roles.dart';
import '../../core/api/repositories/blogs.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/storage.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/admin_header.dart';
import '../../core/widgets/app_background.dart';
import 'details.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  static const _pageSize = 20;

  final _blogsRepo = BlogsRepository();
  final _scroll = ScrollController();

  final List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;

  bool get _canCreate => RoleTypes.isAnnouncementsRole(Storage.role);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<List<Map<String, dynamic>>> _fetch(int start) async {
    final res = await _blogsRepo.getAnnouncements(
      language: 'en',
      start: start,
      size: _pageSize,
    );
    final raw = res['blogList'] as List<dynamic>? ?? [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _items.isEmpty;
      _error = null;
    });
    try {
      final list = await _fetch(0);
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(list);
        _hasMore = list.length >= _pageSize;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _loading || _items.isEmpty) return;
    setState(() => _loadingMore = true);
    try {
      final list = await _fetch(_items.length);
      if (!mounted) return;
      setState(() {
        _items.addAll(list);
        _hasMore = list.length >= _pageSize;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _create() async {
    await context.push('/admin/announcements/create');
    _load();
  }

  Future<void> _open(Map<String, dynamic> item) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AnnouncementDetailsScreen(announcement: item),
      ),
    );
    if (changed == true) _load();
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
                title: AppLocalizations.t('announcements.title'),
                actions: [
                  if (_canCreate)
                    IconButton(
                      icon: Icon(Icons.add_circle_rounded,
                          color: colors.accentPrimary, size: 24),
                      onPressed: _create,
                    ),
                ],
              ),
              Expanded(child: _buildBody(colors)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AppPalette colors) {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(color: colors.accentPrimary),
      );
    }

    if (_error != null && _items.isEmpty) {
      return _StateView(
        icon: Icons.error_outline_rounded,
        color: colors.error,
        text: _error!,
        actionLabel: AppLocalizations.t('common.retry'),
        onAction: _load,
      );
    }

    return RefreshIndicator(
      color: colors.accentPrimary,
      backgroundColor: colors.surfaceElevated,
      onRefresh: _load,
      child: _items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: _StateView(
                    icon: Icons.campaign_rounded,
                    color: colors.textMuted,
                    text: AppLocalizations.t('announcements.empty'),
                  ),
                ),
              ],
            )
          : ListView.builder(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                24 + MediaQuery.of(context).padding.bottom,
              ),
              itemCount: _items.length + (_loadingMore ? 1 : 0),
              itemBuilder: (context, i) {
                if (i >= _items.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.accentPrimary,
                        ),
                      ),
                    ),
                  );
                }
                final item = _items[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _AnnouncementCard(item: item, onTap: () => _open(item)),
                );
              },
            ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.item, required this.onTap});

  final Map<String, dynamic> item;
  final VoidCallback onTap;

  static final _tagRe = RegExp(r'\[[BICS]+\]');
  static final _linkRe = RegExp(r'\[([^|\]]+)\|[^\]]+\]');

  String _preview(String raw) {
    return raw
        .replaceAllMapped(_linkRe, (m) => m.group(1) ?? '')
        .replaceAll(_tagRe, '')
        .replaceAll(RegExp(r'\n\s*\n+'), '\n')
        .trim();
  }

  String? _coverUrl() {
    try {
      final ext = item['extensions'];
      final style = ext is Map ? ext['style'] : null;
      final list = style is Map ? style['backgroundMediaList'] : null;
      if (list is List && list.isNotEmpty && list[0] is List) {
        final url = (list[0] as List)[1];
        if (url is String && url.isNotEmpty) return url;
      }
    } catch (_) {}
    return null;
  }

  String _date(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final d = DateTime.parse(iso).toLocal();
      String two(int v) => v.toString().padLeft(2, '0');
      return '${two(d.day)}.${two(d.month)}.${d.year}  ${two(d.hour)}:${two(d.minute)}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    const radius = BorderRadius.all(Radius.circular(20));

    final author = item['author'] is Map
        ? Map<String, dynamic>.from(item['author'] as Map)
        : <String, dynamic>{};
    final authorName = author['nickname'] as String? ??
        AppLocalizations.t('announcements.details.system_author');
    final avatar = author['icon'] as String?;
    final title = (item['title'] as String? ??
            AppLocalizations.t('announcements.details.no_title'))
        .trim();
    final preview = _preview(item['content'] as String? ?? '');
    final date = _date(item['createdTime'] as String?);
    final cover = _coverUrl();

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        color: colors.glassFill,
        border: Border.all(color: colors.glassBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (cover != null)
                AspectRatio(
                  aspectRatio: 16 / 7,
                  child: Image.network(
                    cover,
                    fit: BoxFit.cover,
                    loadingBuilder: (c, child, p) => p == null
                        ? child
                        : Container(
                            color: colors.accentPrimary.withValues(alpha: 0.08),
                          ),
                    errorBuilder: (c, e, s) => Container(
                      color: colors.accentPrimary.withValues(alpha: 0.08),
                      child: Icon(Icons.image_not_supported_outlined,
                          color: colors.textMuted),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor:
                              colors.accentPrimary.withValues(alpha: 0.2),
                          backgroundImage:
                              avatar != null ? NetworkImage(avatar) : null,
                          child: avatar == null
                              ? Icon(Icons.person,
                                  size: 16, color: colors.accentPrimary)
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                authorName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (date.isNotEmpty)
                                Text(
                                  date,
                                  style: TextStyle(
                                    color: colors.textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            color: colors.textMuted),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    if (preview.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        preview,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StateView extends StatelessWidget {
  const _StateView({
    required this.icon,
    required this.color,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final Color color;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.10),
              ),
              child: Icon(icon, size: 36, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(color: color, fontSize: 13.5, height: 1.4),
            ),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: onAction,
                child: Text(
                  actionLabel!,
                  style: TextStyle(
                    color: colors.accentPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}