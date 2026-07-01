import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/admin_header.dart';

class AdminDashboardScreen extends StatelessWidget {

  const AdminDashboardScreen({
    super.key,
  });


  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    final sections = <_AdminSection>[
      _AdminSection(
        Icons.emoji_events_outlined,
        AppLocalizations.t('admin.section.events'),
        AppLocalizations.t('admin.section.events_desc'),
        '/admin/events',
        ),
      _AdminSection(
        Icons.shield_outlined,
        AppLocalizations.t('admin.section.roles'),
        AppLocalizations.t('admin.section.roles_desc'),
        '/admin/roles',
      ),
      _AdminSection(
        Icons.flag_outlined,
        AppLocalizations.t('admin.section.reports'),
        AppLocalizations.t('admin.section.reports_desc'),
        '/admin/reports',
      ),
      _AdminSection(
        Icons.gavel_rounded,
        AppLocalizations.t('admin.section.usr_moderation'),
        AppLocalizations.t('admin.section.usr_moderation_desc'),
        '/admin/user/moderation',
      ),

    ];

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
              AdminHeader(title: AppLocalizations.t('admin.title')),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 1.05,
                  ),
                  itemCount: sections.length,
                  itemBuilder: (context, i) => _card(context, colors, sections[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(BuildContext context, AppPalette colors, _AdminSection s) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(s.route),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.glassFill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.glassBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(s.icon, color: colors.accentPrimary, size: 26),
              const Spacer(),
              Text(
                s.title,
                style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                s.subtitle,
                style: TextStyle(color: colors.textMuted, fontSize: 11.5, height: 1.3),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminSection {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  const _AdminSection(this.icon, this.title, this.subtitle, this.route);
}