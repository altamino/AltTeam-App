import 'package:flutter/material.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/admin_header.dart';
import '../../core/widgets/coming_soon_placeholder.dart';

class AdminLinkModerationScreen extends StatefulWidget {
  const AdminLinkModerationScreen({super.key});

  @override
  State<AdminLinkModerationScreen> createState() => _AdminLinkModerationScreenState();
}

class _AdminLinkModerationScreenState extends State<AdminLinkModerationScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _check() {
    // TODO: detect resource type from the link (user/post/community/etc.)
    // and load the matching moderation actions for it.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.t('admin.links.not_ready'))),
    );
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
              AdminHeader(title: AppLocalizations.t('admin.links.title')),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: colors.glassFill,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.glassBorder),
                        ),
                        child: TextField(
                          controller: _controller,
                          style: TextStyle(color: colors.textPrimary, fontSize: 13.5),
                          decoration: InputDecoration(
                            hintText: AppLocalizations.t('admin.links.hint'),
                            hintStyle: TextStyle(color: colors.textMuted, fontSize: 13.5),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _check,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.accentPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(AppLocalizations.t('admin.links.check')),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ComingSoonPlaceholder(
                  icon: Icons.link,
                  text: AppLocalizations.t('admin.links.empty'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}