import 'dart:io';

import 'package:flutter/material.dart';

import '../deps.dart';
import '../edit_community_controller.dart';
import '../edit_tab.dart';
import '../widgets/theme_card.dart';
import '../widgets/ui.dart';

class MediaTab extends EditTab {
  const MediaTab();

  @override
  String get id => 'media';
  @override
  IconData get icon => Icons.image_rounded;
  @override
  String get titleKey => 'admin.community.tab_media';

  @override
  Widget build(BuildContext context, EditCommunityController c) {
    return TabScroll(
      children: [
        _CoverCard(controller: c),
        const SizedBox(height: 14),
        ThemeCard(controller: c),
      ],
    );
  }
}

class _CoverCard extends StatelessWidget {
  const _CoverCard({required this.controller});
  final EditCommunityController controller;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final c = controller;

    ImageProvider? image;
    if (c.newCover != null) {
      image = FileImage(File(c.newCover!.path));
    } else if (c.currentCoverUrl != null) {
      image = NetworkImage(c.currentCoverUrl!);
    }

    return SectionCard(
      title: AppLocalizations.t('admin.community.field_cover'),
      icon: Icons.photo_size_select_actual_rounded,
      child: Center(
        child: GestureDetector(
          onTap: c.pickCover,
          child: Stack(
            children: [
              Container(
                width: 170,
                height: 302,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: colors.glassFillStrong,
                  border: Border.all(color: colors.glassBorder),
                  image: image != null
                      ? DecorationImage(image: image, fit: BoxFit.cover)
                      : null,
                ),
                child: image == null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_photo_alternate_rounded,
                                size: 34, color: colors.textMuted),
                            const SizedBox(height: 8),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                AppLocalizations.t(
                                    'admin.community.field_cover_hint'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: colors.textMuted, fontSize: 11.5),
                              ),
                            ),
                          ],
                        ),
                      )
                    : null,
              ),
              if (image != null)
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.edit_rounded,
                        color: Colors.white, size: 17),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}