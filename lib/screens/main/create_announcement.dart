import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/admin_header.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/api/repositories/links.dart';
import '../../core/api/repositories/blogs.dart';
import 'announcement_details.dart';

class AdminCreateAnnouncementScreen extends StatefulWidget {

  final Map<String, dynamic>? announcement;

  const AdminCreateAnnouncementScreen({super.key, this.announcement});

  @override
  State<AdminCreateAnnouncementScreen> createState() => _AdminCreateAnnouncementScreenState();
}

class _AdminCreateAnnouncementScreenState extends State<AdminCreateAnnouncementScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _blogsRepo = BlogsRepository();
  final _linksRepo = LinksRepository();
  final _picker = ImagePicker();

  bool _publishing = false;
  String? _uploadedBgUrl;
  String? _uploadedBgFileName;


  bool get _isEditing => widget.announcement != null;

  @override
  void initState() {
    super.initState();

    if (_isEditing) {
      final blog = widget.announcement!;
      _titleController.text = blog['title'] as String? ?? '';
      _bodyController.text = blog['content'] as String? ?? '';

   
      final extensions = blog['extensions'] as Map<String, dynamic>? ?? {};
      final style = extensions['style'] as Map<String, dynamic>? ?? {};
      final bgList = style['backgroundMediaList'] as List<dynamic>?;
      if (bgList != null && bgList.isNotEmpty && bgList[0] is List) {
        _uploadedBgUrl = bgList[0][1] as String?;
        final fileInfo = bgList[0].length > 5 ? bgList[0][5] as Map<String, dynamic>? : null;
        _uploadedBgFileName = fileInfo?['fileName'] as String?;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _insertFormatTag(String tag) {
    final text = _bodyController.text;
    final selection = _bodyController.selection;

    if (selection.start == -1) {
      _bodyController.text = '$tag $text';
      return;
    }

    final newText = text.replaceRange(selection.start, selection.end, tag);
    _bodyController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + tag.length),
    );
  }

  Future<void> _pickAndUploadBackground() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() => _publishing = true);
      final response = await _linksRepo.uploadMedia(file: image);

      setState(() {
        _uploadedBgUrl = response['mediaValue'];
        _uploadedBgFileName = image.name;
        _publishing = false;
      });

      if (!mounted) return;
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
        AppLocalizations.t('announcements.create.background.upload_error', args: {'error': '$e'}),
        type: SnackType.error,
      );
    }
  }

  Future<void> _publishOrSave() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.isEmpty || body.isEmpty) return;

    setState(() => _publishing = true);

    try {
      Map<String, dynamic> response;

      if (_isEditing) {

        final blogId = widget.announcement!['blogId'] as String;
        final ndcId = widget.announcement!['ndcId'] as int? ?? 0;

        response = await _blogsRepo.editBlog(
          blogId: blogId,
          ndcId: ndcId,
          title: title,
          content: body,
          bgMediaUrl: _uploadedBgUrl,
          bgMediaFileName: _uploadedBgFileName,
        );
      } else {
   
        response = await _blogsRepo.createBlog(
          ndcId: 0,
          title: title,
          content: body,
          bgMediaUrl: _uploadedBgUrl,
          bgMediaFileName: _uploadedBgFileName,
          language: 'en',
        );
      }

      if (!mounted) return;
      setState(() => _publishing = false);

      final resultBlog = response['blog'] as Map<String, dynamic>?;

      if (resultBlog != null) {
        if (_isEditing) {

          Navigator.pop(context, resultBlog);
        } else {

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AnnouncementDetailsScreen(announcement: resultBlog),
            ),
          );
        }
      } else {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _publishing = false);
      AppSnackbar.show(
        context,
        AppLocalizations.t('announcements.create.publish_error', args: {'error': '$e'}),
        type: SnackType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

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
                title: _isEditing
                    ? AppLocalizations.t('announcements.create.edit_title')
                    : AppLocalizations.t('announcements.create.title'),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.t('announcements.create.title_label'),
                        style: TextStyle(color: colors.textMuted, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      _field(colors, _titleController, AppLocalizations.t('announcements.create.title_hint')),

                      const SizedBox(height: 18),

                      Text(
                        AppLocalizations.t('announcements.create.body_label'),
                        style: TextStyle(color: colors.textMuted, fontSize: 12),
                      ),
                      const SizedBox(height: 8),

                      _buildFormatToolbar(colors),
                      const SizedBox(height: 6),

                      _field(colors, _bodyController, AppLocalizations.t('announcements.create.body_hint'), maxLines: 8),
                      const SizedBox(height: 16),

                      _buildBgAttachmentTile(colors),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: _publishing ? null : _publishOrSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.accentPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _publishing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  _isEditing
                                      ? AppLocalizations.t('announcements.create.save')
                                      : AppLocalizations.t('announcements.create.publish'),
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

  Widget _buildFormatToolbar(AppPalette colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: colors.glassFill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _formatButton(
            colors: colors,
            text: 'B',
            hint: AppLocalizations.t('announcements.create.format.bold'),
            onTap: () => _insertFormatTag('[B]'),
          ),
          _formatButton(
            colors: colors,
            text: 'I',
            hint: AppLocalizations.t('announcements.create.format.italic'),
            onTap: () => _insertFormatTag('[I]'),
          ),
          _formatButton(
            colors: colors,
            text: 'C',
            hint: AppLocalizations.t('announcements.create.format.center'),
            onTap: () => _insertFormatTag('[C]'),
          ),
          _formatButton(
            colors: colors,
            text: '⚡ ${AppLocalizations.t('announcements.create.format.link')}',
            hint: AppLocalizations.t('announcements.create.format.link'),
            onTap: () => _insertFormatTag('[${AppLocalizations.t('announcements.create.format.link')}|https://]'),
          ),
        ],
      ),
    );
  }

  Widget _formatButton({
    required AppPalette colors,
    required String text,
    required String hint,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: hint,
      child: TextButton(
        style: TextButton.styleFrom(
          minimumSize: const Size(44, 32),
          padding: EdgeInsets.zero,
        ),
        onPressed: onTap,
        child: Text(text, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }

  Widget _buildBgAttachmentTile(AppPalette colors) {
    final hasBg = _uploadedBgUrl != null;

    return InkWell(
      onTap: _publishing ? null : _pickAndUploadBackground,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colors.glassFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: hasBg ? colors.accentPrimary.withOpacity(0.4) : colors.glassBorder),
        ),
        child: Row(
          children: [
            Icon(
              hasBg ? Icons.collections : Icons.image_outlined,
              color: hasBg ? colors.accentPrimary : colors.textMuted,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hasBg
                    ? AppLocalizations.t('announcements.create.background.attached')
                    : AppLocalizations.t('announcements.create.background.add'),
                style: TextStyle(color: colors.textPrimary, fontSize: 13),
              ),
            ),
            if (hasBg)
              IconButton(
                icon: Icon(Icons.close, size: 18, color: colors.error),
                onPressed: () => setState(() {
                  _uploadedBgUrl = null;
                  _uploadedBgFileName = null;
                }),
              ),
          ],
        ),
      ),
    );
  }

  Widget _field(AppPalette colors, TextEditingController controller, String hint, {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: colors.glassFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.glassBorder),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(color: colors.textPrimary, fontSize: 13.5),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: colors.textMuted, fontSize: 13.5),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
}