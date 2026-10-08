import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/objects/args/roles.dart';
import '../../core/api/repositories/blogs.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/storage.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/admin_header.dart';
import '../../core/widgets/app_background.dart';
import '../../core/widgets/app_snackbar.dart';
import 'create.dart';

class AnnouncementDetailsScreen extends StatefulWidget {
  const AnnouncementDetailsScreen({super.key, required this.announcement});

  final Map<String, dynamic> announcement;

  @override
  State<AnnouncementDetailsScreen> createState() =>
      _AnnouncementDetailsScreenState();
}

class _AnnouncementDetailsScreenState extends State<AnnouncementDetailsScreen> {
  static final _tagRe = RegExp(r'\[([BICS]+)\]');
  static final _linkRe = RegExp(r'\[([^|\]]+)\|([^\]]+)\]');

  final _blogsRepo = BlogsRepository();
  final List<TapGestureRecognizer> _recognizers = [];

  late Map<String, dynamic> _current;
  bool _processing = false;

  bool get _canManage => RoleTypes.isAnnouncementsRole(Storage.role);

  @override
  void initState() {
    super.initState();
    _current = widget.announcement;
  }

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final d = DateTime.parse(iso).toLocal();
      String two(int v) => v.toString().padLeft(2, '0');
      return '${two(d.day)}.${two(d.month)}.${d.year}  ${two(d.hour)}:${two(d.minute)}';
    } catch (_) {
      return '';
    }
  }

  String? _coverUrl() {
    try {
      final ext = _current['extensions'];
      final style = ext is Map ? ext['style'] : null;
      final list = style is Map ? style['backgroundMediaList'] : null;
      if (list is List && list.isNotEmpty && list[0] is List) {
        final url = (list[0] as List)[1];
        if (url is String && url.isNotEmpty) return url;
      }
    } catch (_) {}
    return null;
  }

  List<String> _mediaUrls() {
    final media = _current['mediaList'];
    if (media is! List) return const [];
    final urls = <String>[];
    for (final m in media) {
      if (m is List && m.length > 1 && m[1] is String) {
        final url = m[1] as String;
        if (url.isNotEmpty) urls.add(url);
      }
    }
    return urls;
  }

  Future<void> _openLink(String raw) async {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _deletePost() async {
    final colors = AppColors.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => AlertDialog(
        backgroundColor:
            Theme.of(ctx).dialogBackgroundColor.withValues(alpha: 0.96),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: colors.glassBorder.withValues(alpha: 0.4)),
        ),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.error.withValues(alpha: 0.12),
              ),
              child: Icon(Icons.delete_outline_rounded,
                  color: colors.error, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.t('announcements.details.delete_dialog_title'),
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          AppLocalizations.t('announcements.details.delete_dialog_message'),
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              AppLocalizations.t('announcements.details.cancel'),
              style: TextStyle(
                color: colors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              backgroundColor: colors.error.withValues(alpha: 0.12),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              AppLocalizations.t('announcements.details.delete'),
              style: TextStyle(
                color: colors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _processing = true);
    try {
      final blogId = _current['blogId'] as String;
      final ndcId = _current['ndcId'] as int? ?? 0;

      await _blogsRepo.deleteBlog(blogId: blogId, ndcId: ndcId);

      if (!mounted) return;
      AppSnackbar.show(
        context,
        AppLocalizations.t('announcements.details.deleted_success'),
        type: SnackType.success,
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _processing = false);
      AppSnackbar.show(
        context,
        AppLocalizations.t('announcements.details.delete_error',
            args: {'error': '$e'}),
        type: SnackType.error,
      );
    }
  }

  Future<void> _editPost() async {
    final updated = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => AdminCreateAnnouncementScreen(announcement: _current),
      ),
    );

    if (updated == null || !mounted) return;
    setState(() => _current = updated);
    AppSnackbar.show(
      context,
      AppLocalizations.t('announcements.details.edit_success'),
      type: SnackType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    final author = _current['author'] is Map
        ? Map<String, dynamic>.from(_current['author'] as Map)
        : <String, dynamic>{};
    final authorName = author['nickname'] as String? ??
        AppLocalizations.t('announcements.details.system_author');
    final authorAvatar = author['icon'] as String?;
    final title = (_current['title'] as String? ??
            AppLocalizations.t('announcements.details.no_title'))
        .trim();
    final rawContent = _current['content'] as String? ?? '';
    final date = _formatDate(_current['createdTime'] as String?);
    final cover = _coverUrl();
    final media = _mediaUrls();

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              AdminHeader(
                title: AppLocalizations.t('announcements.details.title'),
                actions: [
                  if (_processing)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.textMuted,
                        ),
                      ),
                    )
                  else if (_canManage) ...[
                    IconButton(
                      icon: Icon(Icons.edit_rounded,
                          color: colors.accentPrimary, size: 20),
                      onPressed: _editPost,
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_rounded,
                          color: colors.error, size: 20),
                      onPressed: _deletePost,
                    ),
                  ],
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    10,
                    16,
                    24 + MediaQuery.of(context).padding.bottom,
                  ),
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: colors.glassFill,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: colors.glassBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (cover != null)
                          AspectRatio(
                            aspectRatio: 16 / 8,
                            child: Image.network(
                              cover,
                              fit: BoxFit.cover,
                              loadingBuilder: (c, child, p) => p == null
                                  ? child
                                  : Container(
                                      color: colors.accentPrimary
                                          .withValues(alpha: 0.08),
                                    ),
                              errorBuilder: (c, e, s) => Container(
                                color:
                                    colors.accentPrimary.withValues(alpha: 0.08),
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  color: colors.textMuted,
                                ),
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _AuthorRow(
                                name: authorName,
                                avatarUrl: authorAvatar,
                                date: date,
                              ),
                              const SizedBox(height: 18),
                              Text(
                                title,
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  height: 1.3,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: 44,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: colors.accentPrimary,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(height: 18),
                              _buildFormattedContent(rawContent, colors),
                              if (media.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                _ImageGallery(urls: media),
                              ],
                            ],
                          ),
                        ),
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

  Widget _buildFormattedContent(String raw, AppPalette colors) {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    final widgets = <Widget>[];

    for (final line in raw.split('\n')) {
      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 10));
        continue;
      }

      final letters =
          _tagRe.allMatches(line).map((m) => m.group(1) ?? '').join();
      final isBold = letters.contains('B');
      final isItalic = letters.contains('I');
      final isCenter = letters.contains('C');

      final clean = line.replaceAll(_tagRe, '').trim();

      final baseStyle = TextStyle(
        color: colors.textPrimary,
        fontSize: 14.5,
        height: 1.55,
        fontWeight: isBold ? FontWeight.w700 : FontWeight.normal,
        fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
      );

      final spans = <InlineSpan>[];
      var last = 0;

      for (final m in _linkRe.allMatches(clean)) {
        if (m.start > last) {
          spans.add(TextSpan(
            text: clean.substring(last, m.start),
            style: baseStyle,
          ));
        }
        final linkText = m.group(1) ?? '';
        final linkUrl = m.group(2) ?? '';

        final recognizer = TapGestureRecognizer()
          ..onTap = () => _openLink(linkUrl);
        _recognizers.add(recognizer);

        spans.add(TextSpan(
          text: linkText,
          recognizer: recognizer,
          style: baseStyle.copyWith(
            color: colors.accentPrimary,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.underline,
            decorationColor: colors.accentPrimary.withValues(alpha: 0.5),
          ),
        ));
        last = m.end;
      }

      if (last < clean.length) {
        spans.add(TextSpan(text: clean.substring(last), style: baseStyle));
      }

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: SizedBox(
            width: double.infinity,
            child: RichText(
              textAlign: isCenter ? TextAlign.center : TextAlign.left,
              text: TextSpan(children: spans),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}

class _AuthorRow extends StatelessWidget {
  const _AuthorRow({
    required this.name,
    required this.avatarUrl,
    required this.date,
  });

  final String name;
  final String? avatarUrl;
  final String date;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: colors.accentPrimary.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          child: CircleAvatar(
            radius: 20,
            backgroundColor: colors.accentPrimary.withValues(alpha: 0.12),
            backgroundImage:
                avatarUrl != null ? NetworkImage(avatarUrl!) : null,
            child: avatarUrl == null
                ? Icon(Icons.person, color: colors.accentPrimary, size: 20)
                : null,
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
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (date.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  date,
                  style: TextStyle(color: colors.textMuted, fontSize: 11.5),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ImageGallery extends StatelessWidget {
  const _ImageGallery({required this.urls});
  final List<String> urls;

  void _open(BuildContext context, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _ImageViewer(urls: urls, initialIndex: index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (urls.length == 1) {
      return AspectRatio(
        aspectRatio: 16 / 10,
        child: _Tile(url: urls.first, onTap: () => _open(context, 0)),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: urls.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemBuilder: (context, i) =>
          _Tile(url: urls[i], onTap: () => _open(context, i)),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.url, required this.onTap});
  final String url;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    const radius = BorderRadius.all(Radius.circular(16));

    return ClipRRect(
      borderRadius: radius,
      child: Material(
        color: colors.accentPrimary.withValues(alpha: 0.08),
        child: InkWell(
          onTap: onTap,
          child: Image.network(
            url,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            loadingBuilder: (c, child, p) => p == null
                ? child
                : Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.accentPrimary,
                      ),
                    ),
                  ),
            errorBuilder: (c, e, s) => Center(
              child: Icon(Icons.image_not_supported_outlined,
                  color: colors.textMuted),
            ),
          ),
        ),
      ),
    );
  }
}

class _ImageViewer extends StatefulWidget {
  const _ImageViewer({required this.urls, required this.initialIndex});
  final List<String> urls;
  final int initialIndex;

  @override
  State<_ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<_ImageViewer> {
  late final PageController _controller =
      PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.urls.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Center(
                child: Image.network(
                  widget.urls[i],
                  fit: BoxFit.contain,
                  loadingBuilder: (c, child, p) => p == null
                      ? child
                      : const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                  errorBuilder: (c, e, s) => const Icon(
                    Icons.image_not_supported_outlined,
                    color: Colors.white54,
                    size: 48,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  if (widget.urls.length > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_index + 1} / ${widget.urls.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}