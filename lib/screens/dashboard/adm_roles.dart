import 'package:flutter/material.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/admin_header.dart';
import '../../core/widgets/coming_soon_placeholder.dart';

class AdminRolesScreen extends StatelessWidget {
  const AdminRolesScreen({super.key});

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
              AdminHeader(title: AppLocalizations.t('admin.roles.title')),
              Expanded(
                child: ComingSoonPlaceholder(
                  icon: Icons.shield_outlined,
                  text: AppLocalizations.t('admin.roles.empty'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}