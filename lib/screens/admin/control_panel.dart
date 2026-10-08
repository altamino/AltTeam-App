import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/admin_header.dart';
import '../../core/widgets/app_background.dart';

class _AdminItem {
  const _AdminItem({
    required this.icon,
    required this.titleKey,
    required this.descKey,
    required this.route,
  });

  final IconData icon;
  final String titleKey;
  final String descKey;
  final String route;
}

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  static const _items = <_AdminItem>[
    _AdminItem(
      icon: Icons.shield_rounded,
      titleKey: 'admin.panel.moderation',
      descKey: 'admin.panel.moderation_desc',
      route: '/admin/moderation',
    ),
    _AdminItem(
      icon: Icons.storefront_rounded,
      titleKey: 'admin.panel.store',
      descKey: 'admin.panel.store_desc',
      route: '/admin/store',
    ),
    _AdminItem(
      icon: Icons.explore_rounded,
      titleKey: 'admin.panel.discover',
      descKey: 'admin.panel.discover_desc',
      route: '/admin/discover',
    ),
    _AdminItem(
      icon: Icons.lock_reset_rounded,
      titleKey: 'admin.panel.password_reset',
      descKey: 'admin.panel.password_reset_desc',
      route: '/admin/password-reset',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              AdminHeader(title: AppLocalizations.t('admin.panel.title')),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    24 + MediaQuery.of(context).padding.bottom,
                  ),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final item = _items[i];
                    return _AdminTile(
                      icon: item.icon,
                      title: AppLocalizations.t(item.titleKey),
                      subtitle: AppLocalizations.t(item.descKey),
                      onTap: () => context.push(item.route),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminTile extends StatelessWidget {
  const _AdminTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    const radius = BorderRadius.all(Radius.circular(20));

    return Material(
      color: colors.glassFill,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: colors.glassBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: colors.accentPrimary.withValues(alpha: 0.12),
                  border: Border.all(
                    color: colors.accentPrimary.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(icon, color: colors.accentPrimary, size: 25),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                  ],
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