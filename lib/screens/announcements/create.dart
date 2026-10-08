import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api/repositories/blogs.dart';
import '../../core/api/repositories/links.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/admin_header.dart';
import '../../core/widgets/app_background.dart';
import '../../core/widgets/app_snackbar.dart';
import 'details.dart';

class AdminCreateAnnouncementScreen extends StatefulWidget {
  const AdminCreateAnnouncementScreen({super.key, this.announcement});

  final Map<String, dynamic>? announcement;

  @override
  State<AdminCreateAnnouncementScreen> createState() =>
      _AdminCreateAnnouncementScreenState();
}

class _Media {
  const _Media(this.url, this.name);
  final String url;
  final String? name;

  List<dynamic> toApi() => [
        100,
        url,
        null,
        null,
        null,
        {'fileName': name},
      ];
}

class _AdminCreateAnnouncementScreenState
    extends State<AdminCreateAnnouncementScreen> {
  static const _maxImages = 10;

  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _blogsRepo = BlogsRepository();
  final _linksRepo = LinksRepository();
  final _picker = ImagePicker();

  bool _publishing = false;
  int _uploading = 0;
  String? _bgUrl;
  String? _bgFileName;
  final List<_Media> _images = [];

  bool get _isEditing => widget.announcement != null;
  bool get _busy => _publishing || _uploading > 0;

  @override
  void initState() {
    super.initState();

    if (_isEditing) {
      final blog = widget.announcement!;
      _titleController.text = blog['title'] as String? ?? '';
      _bodyController.text = blog['content'] as String? ?? '';

      final ext = blog['extensions'] as Map<String, dynamic>? ?? {};
      final style = ext['style'] as Map<String, dynamic>? ?? {};
      final bgList = style['backgroundMediaList'] as List<dynamic>?;
      if (bgList != null && bgList.isNotEmpty && bgList[0] is List) {
        final item = bgList[0] as List;
        _bgUrl = item.length > 1 ? item[1] as String? : null;
        final info = item.length > 5 ? item[5] : null;
        _bgFileName = info is Map ? info['fileName'] as String? : null;
      }

      final media = blog['mediaList'];
      if (media is List) {
        for (final m in media) {
          if (m is List && m.length > 1 && m[1] is String) {
            final info = m.length > 5 ? m[5] : null;
            _images.add(_Media(
              m[1] as String,
              info is Map ? info['fileName'] as String? : null,
            ));
          }
        }
      }
    }

    _bodyController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _insertTag(String tag) {
    final text = _bodyController.text;
    final sel = _bodyController.selection;

    if (!sel.isValid || sel.start < 0) {
      final newText = '$text$tag';
      _bodyController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
      return;
    }

    final newText = text.replaceRange(sel.start, sel.end, tag);
    _bodyController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: sel.start + tag.length),
    );
  }

  Future<void> _pickBackground() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (image == null) return;

      setState(() => _publishing = true);
      final response = await _linksRepo.uploadMedia(file: image);

      if (!mounted) return;
      setState(() {
        _bgUrl = response['mediaValue'];
        _bgFileName = image.name;
        _publishing = false;
      });

      AppSnackbar.show(
        context,
        AppLocalizations.t('announcements.create.background.uploaded_success'),
        type: SnackType.success,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _publishing = false);
      AppSnackbar.show(
        context,
        AppLocalizations.t('announcements.create.background.upload_error',
            args: {'error': '$e'}),
        type: SnackType.error,
      );
    }
  }

  Future<void> _addImages() async {
    final remaining = _maxImages - _images.length - _uploading;
    if (remaining <= 0) {
      AppSnackbar.show(
        context,
        AppLocalizations.t('announcements.create.images.limit',
            args: {'count': '$_maxImages'}),
        type: SnackType.error,
      );
      return;
    }

    try {
      final picked = await _picker.pickMultiImage(imageQuality: 90);
      if (picked.isEmpty || !mounted) return;

      final files = picked.take(remaining).toList();
      setState(() => _uploading += files.length);

      for (final f in files) {
        try {
          final res = await _linksRepo.uploadMedia(file: f);
          final url = res['mediaValue'] as String?;
          if (!mounted) return;
          if (url != null) {
            setState(() => _images.add(_Media(url, f.name)));
          }
        } catch (e) {
          if (!mounted) return;
          AppSnackbar.show(
            context,
            AppLocalizations.t('announcements.create.images.upload_error',
                args: {'error': '$e'}),
            type: SnackType.error,
          );
        } finally {
          if (mounted) setState(() => _uploading--);
        }
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(
        context,
        AppLocalizations.t('announcements.create.images.upload_error',
            args: {'error': '$e'}),
        type: SnackType.error,
      );
    }
  }

  Future<void> _publishOrSave() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      AppSnackbar.show(
        context,
        AppLocalizations.t('announcements.create.fill_required'),
        type: SnackType.error,
      );
      return;
    }

    setState(() => _publishing = true);

    try {
      Map<String, dynamic> response;
      final mediaList = _images.map((m) => m.toApi()).toList();

      if (_isEditing) {
        response = await _blogsRepo.editBlog(
          blogId: widget.announcement!['blogId'] as String,
          ndcId: widget.announcement!['ndcId'] as int? ?? 0,
          title: title,
          content: body,
          bgMediaUrl: _bgUrl,
          bgMediaFileName: _bgFileName,
          mediaList: mediaList,
        );
      } else {
        response = await _blogsRepo.createBlog(
          ndcId: 0,
          title: title,
          content: body,
          bgMediaUrl: _bgUrl,
          bgMediaFileName: _bgFileName,
          language: 'en',
          mediaList: mediaList.isEmpty ? null : mediaList,
        );
      }

      if (!mounted) return;
      setState(() => _publishing = false);

      final resultBlog = response['blog'] as Map<String, dynamic>?;

      if (resultBlog == null) {
        Navigator.pop(context, true);
        return;
      }

      if (_isEditing) {
        Navigator.pop(context, resultBlog);
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => AnnouncementDetailsScreen(announcement: resultBlog),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _publishing = false);
      AppSnackbar.show(
        context,
        AppLocalizations.t('announcements.create.publish_error',
            args: {'error': '$e'}),
        type: SnackType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final linkLabel = AppLocalizations.t('announcements.create.format.link');

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              AdminHeader(
                title: _isEditing
                    ? AppLocalizations.t('announcements.create.edit_title')
                    : AppLocalizations.t('announcements.create.title'),
              ),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    24 + MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Label(AppLocalizations.t(
                          'announcements.create.title_label')),
                      const SizedBox(height: 8),
                      _Field(
                        controller: _titleController,
                        hint: AppLocalizations.t(
                            'announcements.create.title_hint'),
                        enabled: !_publishing,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _Label(AppLocalizations.t(
                              'announcements.create.body_label')),
                          const Spacer(),
                          Text(
                            '${_bodyController.text.length}',
                            style: TextStyle(
                              color: colors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _FormatChip(
                            label: 'B',
                            bold: true,
                            tooltip: AppLocalizations.t(
                                'announcements.create.format.bold'),
                            onTap: () => _insertTag('[B]'),
                          ),
                          _FormatChip(
                            label: 'I',
                            italic: true,
                            tooltip: AppLocalizations.t(
                                'announcements.create.format.italic'),
                            onTap: () => _insertTag('[I]'),
                          ),
                          _FormatChip(
                            icon: Icons.format_align_center_rounded,
                            tooltip: AppLocalizations.t(
                                'announcements.create.format.center'),
                            onTap: () => _insertTag('[C]'),
                          ),
                          _FormatChip(
                            icon: Icons.link_rounded,
                            label: linkLabel,
                            tooltip: linkLabel,
                            onTap: () => _insertTag('[$linkLabel|https://]'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _Field(
                        controller: _bodyController,
                        hint: AppLocalizations.t(
                            'announcements.create.body_hint'),
                        maxLines: 10,
                        minLines: 6,
                        enabled: !_publishing,
                      ),
                      const SizedBox(height: 20),
                      _ImagesSection(
                        images: _images,
                        uploading: _uploading,
                        maxImages: _maxImages,
                        busy: _publishing,
                        onAdd: _addImages,
                        onRemove: (i) => setState(() => _images.removeAt(i)),
                      ),
                      const SizedBox(height: 20),
                      _BackgroundPicker(
                        url: _bgUrl,
                        busy: _busy,
                        onPick: _pickBackground,
                        onRemove: () => setState(() {
                          _bgUrl = null;
                          _bgFileName = null;
                        }),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _busy ? null : _publishOrSave,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: colors.accentPrimary,
                            disabledBackgroundColor:
                                colors.accentPrimary.withValues(alpha: 0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _busy
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colors.onAccent,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _isEditing
                                          ? Icons.check_rounded
                                          : Icons.send_rounded,
                                      size: 18,
                                      color: colors.onAccent,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isEditing
                                          ? AppLocalizations.t(
                                              'announcements.create.save')
                                          : AppLocalizations.t(
                                              'announcements.create.publish'),
                                      style: TextStyle(
                                        color: colors.onAccent,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
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
      ),
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
        color: colors.textMuted,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.minLines,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final int? minLines;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.glassFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.glassBorder),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        minLines: minLines,
        cursorColor: colors.accentPrimary,
        style: TextStyle(color: colors.textPrimary, fontSize: 14, height: 1.45),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: colors.textMuted, fontSize: 14),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

class _FormatChip extends StatelessWidget {
  const _FormatChip({
    required this.tooltip,
    required this.onTap,
    this.label,
    this.icon,
    this.bold = false,
    this.italic = false,
  });

  final String tooltip;
  final VoidCallback onTap;
  final String? label;
  final IconData? icon;
  final bool bold;
  final bool italic;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    const radius = BorderRadius.all(Radius.circular(12));

    return Tooltip(
      message: tooltip,
      child: Material(
        color: colors.accentPrimary.withValues(alpha: 0.10),
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minWidth: 42, minHeight: 36),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: colors.accentPrimary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null)
                  Icon(icon, size: 18, color: colors.accentPrimary),
                if (icon != null && label != null) const SizedBox(width: 6),
                if (label != null)
                  Text(
                    label!,
                    style: TextStyle(
                      color: colors.accentPrimary,
                      fontSize: 14,
                      fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ImagesSection extends StatelessWidget {
  const _ImagesSection({
    required this.images,
    required this.uploading,
    required this.maxImages,
    required this.busy,
    required this.onAdd,
    required this.onRemove,
  });

  final List<_Media> images;
  final int uploading;
  final int maxImages;
  final bool busy;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;

  static const double _size = 92;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    const radius = BorderRadius.all(Radius.circular(14));
    final total = images.length + uploading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _Label(AppLocalizations.t('announcements.create.images.title')),
            const Spacer(),
            Text(
              '$total/$maxImages',
              style: TextStyle(color: colors.textMuted, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var i = 0; i < images.length; i++)
              SizedBox(
                width: _size,
                height: _size,
                child: ClipRRect(
                  borderRadius: radius,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        images[i].url,
                        fit: BoxFit.cover,
                        cacheWidth: 300,
                        loadingBuilder: (c, child, p) => p == null
                            ? child
                            : Container(
                                color:
                                    colors.accentPrimary.withValues(alpha: 0.08),
                              ),
                        errorBuilder: (c, e, s) => Container(
                          color: colors.accentPrimary.withValues(alpha: 0.08),
                          child: Icon(Icons.image_not_supported_outlined,
                              color: colors.textMuted),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Material(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: busy ? null : () => onRemove(i),
                            child: const Padding(
                              padding: EdgeInsets.all(5),
                              child: Icon(Icons.close_rounded,
                                  size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            for (var i = 0; i < uploading; i++)
              Container(
                width: _size,
                height: _size,
                decoration: BoxDecoration(
                  borderRadius: radius,
                  color: colors.glassFill,
                  border: Border.all(color: colors.glassBorder),
                ),
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
              ),
            if (total < maxImages)
              Material(
                color: colors.accentPrimary.withValues(alpha: 0.08),
                borderRadius: radius,
                child: InkWell(
                  borderRadius: radius,
                  onTap: busy ? null : onAdd,
                  child: Container(
                    width: _size,
                    height: _size,
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      border: Border.all(
                        color: colors.accentPrimary.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Icon(
                      Icons.add_photo_alternate_rounded,
                      color: colors.accentPrimary,
                      size: 28,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _BackgroundPicker extends StatelessWidget {
  const _BackgroundPicker({
    required this.url,
    required this.busy,
    required this.onPick,
    required this.onRemove,
  });

  final String? url;
  final bool busy;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    const radius = BorderRadius.all(Radius.circular(16));

    if (url != null) {
      return ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: 16 / 7,
              child: Image.network(
                url!,
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
            Positioned(
              top: 8,
              right: 8,
              child: Row(
                children: [
                  _OverlayButton(
                    icon: Icons.edit_rounded,
                    onTap: busy ? null : onPick,
                  ),
                  const SizedBox(width: 8),
                  _OverlayButton(
                    icon: Icons.close_rounded,
                    onTap: busy ? null : onRemove,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: busy ? null : onPick,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: radius,
            color: colors.glassFill,
            border: Border.all(color: colors.glassBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: colors.accentPrimary.withValues(alpha: 0.12),
                ),
                child: Icon(Icons.wallpaper_rounded,
                    color: colors.accentPrimary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  AppLocalizations.t('announcements.create.background.add'),
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverlayButton extends StatelessWidget {
  const _OverlayButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
      ),
    );
  }
}