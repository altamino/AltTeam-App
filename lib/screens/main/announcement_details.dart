import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/storage.dart';
import '../../core/api/repositories/blogs.dart'; 
import '../../core/l10n/app_localizations.dart';
import '../../core/widgets/admin_header.dart';
import 'create_announcement.dart';
import '../../core/api/objects/args/roles.dart';

class AnnouncementDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> announcement;

  const AnnouncementDetailsScreen({super.key, required this.announcement});

  @override
  State<AnnouncementDetailsScreen> createState() => _AnnouncementDetailsScreenState();
}

class _AnnouncementDetailsScreenState extends State<AnnouncementDetailsScreen> {
  final _blogsRepo = BlogsRepository();
  bool _isProcessing = false;
  late Map<String, dynamic> _currentAnnouncement;

  @override
  void initState() {
    super.initState();
    _currentAnnouncement = widget.announcement;
  }


  Future<void> _deletePost() async {
    final colors = AppColors.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.glassFillStrong,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.glassBorder),
        ),
        title: Text(
          AppLocalizations.t('announcements.details.delete_dialog_title'),
          style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        content: Text(
          AppLocalizations.t('announcements.details.delete_dialog_message'),
          style: TextStyle(color: colors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              AppLocalizations.t('announcements.details.cancel'),
              style: TextStyle(color: colors.textMuted, fontWeight: FontWeight.w500),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppLocalizations.t('announcements.details.delete'),
              style: TextStyle(color: colors.error, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);
    try {
      final blogId = _currentAnnouncement['blogId'] as String;
      final ndcId = _currentAnnouncement['ndcId'] as int? ?? 0;

      await _blogsRepo.deleteBlog(blogId: blogId, ndcId: ndcId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.t('announcements.details.deleted_success'))),
      );


      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.t('announcements.details.delete_error', args: {'error': '$e'}))),
      );
    }
  }


  Future<void> _editPost() async {

    final Map<String, dynamic>? updatedBlog = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => AdminCreateAnnouncementScreen(announcement: _currentAnnouncement),
      ),
    );


    if (updatedBlog != null) {
      setState(() {
        _currentAnnouncement = updatedBlog;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.t('announcements.details.edit_success'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final author = _currentAnnouncement['author'] as Map<String, dynamic>? ?? {};
    final authorName = author['nickname'] as String? ?? AppLocalizations.t('announcements.details.system_author');
    final authorAvatar = author['icon'] as String?;
    final title = _currentAnnouncement['title'] as String? ?? AppLocalizations.t('announcements.details.no_title');
    final rawContent = _currentAnnouncement['content'] as String? ?? '';

    final hasAdminRights = RoleTypes.isAnnouncementsRole(Storage.role);

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
              AdminHeader(
                title: AppLocalizations.t('announcements.details.title'),
                actions: [
                  if (_isProcessing)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: colors.textMuted),
                      ),
                    )
                  else if (hasAdminRights) ...[
                    IconButton(
                      icon: Icon(Icons.edit_rounded, color: colors.accentPrimary, size: 20),
                      onPressed: _editPost,
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_rounded, color: colors.error, size: 20),
                      onPressed: _deletePost,
                    ),
                  ],
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: colors.accentPrimary.withOpacity(0.2),
                            backgroundImage: authorAvatar != null ? NetworkImage(authorAvatar) : null,
                            child: authorAvatar == null ? Icon(Icons.person, color: colors.accentPrimary) : null,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            authorName,
                            style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      Divider(height: 30, thickness: 1, color: colors.glassBorder),

                      Text(
                        title.trim(),
                        style: TextStyle(color: colors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      _buildFormattedContent(rawContent, colors),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormattedContent(String rawContent, AppPalette colors) {
    final lines = rawContent.split('\n');
    List<Widget> textWidgets = [];

    for (var line in lines) {
      if (line.trim().isEmpty) {
        textWidgets.add(const SizedBox(height: 8));
        continue;
      }

      bool isBold = line.contains('[B]') || line.contains('[BC]') || line.contains('[IC]') || line.contains('[BIC]');
      bool isItalic = line.contains('[I]') || line.contains('[IC]') || line.contains('[BIC]');
      bool isCenter = line.contains('[C]') || line.contains('[BC]') || line.contains('[IC]') || line.contains('[BIC]');

      String cleanLine = line.replaceAll(RegExp(r'\[[BICS]+\]'), '').trim();
      final linkRegExp = RegExp(r'\[([^|]+)\|([^\]]+)\]');

      if (linkRegExp.hasMatch(cleanLine)) {
        final matches = linkRegExp.allMatches(cleanLine);
        List<InlineSpan> spans = [];
        int lastMatchEnd = 0;

        for (var match in matches) {
          if (match.start > lastMatchEnd) {
            spans.add(TextSpan(text: cleanLine.substring(lastMatchEnd, match.start)));
          }

          final linkText = match.group(1) ?? '';
          final linkUrl = match.group(2) ?? '';

          spans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: GestureDetector(
                onTap: () async {
                  final url = Uri.parse(linkUrl.trim());
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
                child: Text(
                  ' $linkText ',
                  style: TextStyle(
                    color: colors.accentPrimary,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          );
          lastMatchEnd = match.end;
        }

        if (lastMatchEnd < cleanLine.length) {
          spans.add(TextSpan(text: cleanLine.substring(lastMatchEnd)));
        }

        textWidgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Align(
              alignment: isCenter ? Alignment.center : Alignment.topLeft,
              child: RichText(
                textAlign: isCenter ? TextAlign.center : TextAlign.left,
                text: TextSpan(
                  children: spans,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                    fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ),
            ),
          ),
        );
      } else {
        textWidgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Align(
              alignment: isCenter ? Alignment.center : Alignment.topLeft,
              child: Text(
                cleanLine,
                textAlign: isCenter ? TextAlign.center : TextAlign.left,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: textWidgets,
    );
  }
}