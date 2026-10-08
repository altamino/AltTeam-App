import 'package:flutter/material.dart';

import '../deps.dart';
import '../edit_community_controller.dart';
import '../edit_tab.dart';
import '../widgets/ui.dart';

class ContentTab extends EditTab {
  const ContentTab();

  @override
  String get id => 'content';
  @override
  IconData get icon => Icons.article_rounded;
  @override
  String get titleKey => 'admin.community.tab_content';

  @override
  Widget build(BuildContext context, EditCommunityController c) {
    final colors = AppColors.of(context);

    return TabScroll(
      children: [
        SectionCard(
          title: AppLocalizations.t('admin.community.field_description'),
          icon: Icons.notes_rounded,
          child: AminoTextEditor(
            controller: c.description,
            mediaList: c.descriptionMedia,
            hint: AppLocalizations.t('admin.community.field_description_hint'),
            minLines: 4,
          ),
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: AppLocalizations.t('admin.community.field_guidelines'),
          icon: Icons.gavel_rounded,
          child: AminoTextEditor(
            controller: c.guidelines,
            mediaList: c.guidelineMedia,
            hint: AppLocalizations.t('admin.community.field_guidelines_hint'),
            minLines: 6,
          ),
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: AppLocalizations.t('admin.community.field_welcome_message'),
          icon: Icons.waving_hand_rounded,
          trailing: Switch(
            value: c.welcomeEnabled,
            activeThumbColor: colors.accentPrimary,
            onChanged: c.setWelcomeEnabled,
          ),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: c.welcomeEnabled
                ? LabeledField(
                    controller: c.welcome,
                    hint: AppLocalizations.t(
                        'admin.community.field_welcome_message_hint'),
                    minLines: 2,
                    maxLines: 5,
                  )
                : const SizedBox(width: double.infinity),
          ),
        ),
      ],
    );
  }
}