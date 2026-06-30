import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/storage.dart';
import '../../core/api/repositories/blogs.dart'; 
import '../../core/l10n/app_localizations.dart';
import '../../core/widgets/admin_header.dart';
import '../../core/widgets/app_snackbar.dart';
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
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void initState() {
    super.initState();
    _currentAnnouncement = widget.announcement;
  }

  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    super.dispose();
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return '';
    try {
      final dateTime = DateTime.parse(isoString).toLocal();
      final year = dateTime.year;
      final month = dateTime.month.toString().padLeft(2, '0');
      final day = dateTime.day.toString().padLeft(2, '0');
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return '$day.$month.$year  $hour:$minute';
    } catch (_) {
      return '';
    }
  }

Future<void> _deletePost() async {
    final colors = AppColors.of(context);
    final dialogBg = Theme.of(context).dialogBackgroundColor;

    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: dialogBg.withOpacity(0.95), 
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.black.withOpacity(0.2),
          elevation: 24,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: colors.glassBorder.withOpacity(0.4)),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: colors.error, size: 22),
              const SizedBox(width: 10),
              Text(
                AppLocalizations.t('announcements.details.delete_dialog_title'),
                style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          content: Text(
            AppLocalizations.t('announcements.details.delete_dialog_message'),
            style: TextStyle(color: colors.textSecondary, fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
              child: Text(
                AppLocalizations.t('announcements.details.cancel'),
                style: TextStyle(color: colors.textMuted, fontWeight: FontWeight.w500),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                backgroundColor: colors.error.withOpacity(0.1),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                AppLocalizations.t('announcements.details.delete'),
                style: TextStyle(color: colors.error, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);
    try {
      final blogId = _currentAnnouncement['blogId'] as String;
      final ndcId = _currentAnnouncement['ndcId'] as int? ?? 0;

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
      setState(() => _isProcessing = false);
      AppSnackbar.show(
        context, 
        AppLocalizations.t('announcements.details.delete_error', args: {'error': '$e'}),
        type: SnackType.error,
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
      AppSnackbar.show(
        context, 
        AppLocalizations.t('announcements.details.edit_success'),
        type: SnackType.success,
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
    final createdTime = _currentAnnouncement['createdTime'] as String?;

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
          child: Stack(
            children: [
              Positioned(
                top: 40,
                right: -80,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [colors.ambientGlow.withOpacity(0.4), Colors.transparent],
                    ),
                  ),
                ),
              ),
              Column(
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Container(
                            decoration: colors.glassCard(radius: 24),
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: colors.accentPrimary.withOpacity(0.25), width: 1.5),
                                        boxShadow: [
                                          BoxShadow(
                                            color: colors.accentPrimary.withOpacity(0.1),
                                            blurRadius: 10,
                                          )
                                        ]
                                      ),
                                      child: CircleAvatar(
                                        radius: 22,
                                        backgroundColor: colors.accentPrimary.withOpacity(0.1),
                                        backgroundImage: authorAvatar != null ? NetworkImage(authorAvatar) : null,
                                        child: authorAvatar == null ? Icon(Icons.person, color: colors.accentPrimary, size: 20) : null,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            authorName,
                                            style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (createdTime != null) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              _formatDate(createdTime),
                                              style: TextStyle(color: colors.textMuted, fontSize: 11),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  child: Divider(height: 1, thickness: 1, color: colors.glassBorder),
                                ),
                                Text(
                                  title.trim(),
                                  style: TextStyle(
                                    color: colors.textPrimary, 
                                    fontSize: 22, 
                                    fontWeight: FontWeight.bold,
                                    height: 1.3,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                _buildFormattedContent(rawContent, colors),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormattedContent(String rawContent, AppPalette colors) {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    final lines = rawContent.split('\n');
    List<Widget> textWidgets = [];

    for (var line in lines) {
      if (line.trim().isEmpty) {
        textWidgets.add(const SizedBox(height: 10));
        continue;
      }

      bool isBold = line.contains('[B]') || line.contains('[BC]') || line.contains('[IC]') || line.contains('[BIC]');
      bool isItalic = line.contains('[I]') || line.contains('[IC]') || line.contains('[BIC]');
      bool isCenter = line.contains('[C]') || line.contains('[BC]') || line.contains('[IC]') || line.contains('[BIC]');

      String cleanLine = line.replaceAll(RegExp(r'\[[BICS]+\]'), '').trim();
      final linkRegExp = RegExp(r'\[([^|]+)\|([^\]]+)\]');

      final baseStyle = TextStyle(
        color: colors.textPrimary,
        fontSize: 14.5,
        height: 1.55,
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
      );

      if (linkRegExp.hasMatch(cleanLine)) {
        final matches = linkRegExp.allMatches(cleanLine);
        List<InlineSpan> spans = [];
        int lastMatchEnd = 0;

        for (var match in matches) {
          if (match.start > lastMatchEnd) {
            spans.add(TextSpan(
              text: cleanLine.substring(lastMatchEnd, match.start),
              style: baseStyle,
            ));
          }

          final linkText = match.group(1) ?? '';
          final linkUrl = match.group(2) ?? '';

          final recognizer = TapGestureRecognizer()
            ..onTap = () async {
              final url = Uri.parse(linkUrl.trim());
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            };
          _recognizers.add(recognizer);

          spans.add(
            TextSpan(
              text: linkText,
              recognizer: recognizer,
              style: baseStyle.copyWith(
                color: colors.accentPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
          lastMatchEnd = match.end;
        }

        if (lastMatchEnd < cleanLine.length) {
          spans.add(TextSpan(
            text: cleanLine.substring(lastMatchEnd),
            style: baseStyle,
          ));
        }

        textWidgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Align(
              alignment: isCenter ? Alignment.center : Alignment.topLeft,
              child: RichText(
                textAlign: isCenter ? TextAlign.center : TextAlign.left,
                text: TextSpan(children: spans),
              ),
            ),
          ),
        );
      } else {
        textWidgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Align(
              alignment: isCenter ? Alignment.center : Alignment.topLeft,
              child: Text(
                cleanLine,
                textAlign: isCenter ? TextAlign.center : TextAlign.left,
                style: baseStyle,
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