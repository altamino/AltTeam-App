import 'package:flutter/material.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/admin_header.dart';
import '../../../core/widgets/coming_soon_placeholder.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  int _filter = 0; // 0 = open, 1 = resolved

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
              AdminHeader(title: AppLocalizations.t('admin.reports.title')),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Expanded(child: _filterChip(colors, 0, AppLocalizations.t('admin.reports.filter_open'))),
                    const SizedBox(width: 10),
                    Expanded(child: _filterChip(colors, 1, AppLocalizations.t('admin.reports.filter_resolved'))),
                  ],
                ),
              ),
              Expanded(
                child: ComingSoonPlaceholder(
                  icon: Icons.flag_outlined,
                  text: AppLocalizations.t('admin.reports.empty'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip(AppPalette colors, int index, String label) {
    final selected = _filter == index;
    return GestureDetector(
      onTap: () => setState(() => _filter = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? colors.accentPrimary.withOpacity(0.15) : colors.glassFill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? colors.accentPrimary.withOpacity(0.4) : colors.glassBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? colors.accentPrimary : colors.textSecondary,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}