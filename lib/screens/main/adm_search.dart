import 'package:flutter/material.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/admin_header.dart';
import '../../core/widgets/coming_soon_placeholder.dart';

class AdminSearchScreen extends StatefulWidget {
  const AdminSearchScreen({super.key});

  @override
  State<AdminSearchScreen> createState() => _AdminSearchScreenState();
}

class _AdminSearchScreenState extends State<AdminSearchScreen> {
  int _tab = 0; // 0 = users, 1 = communities
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
              AdminHeader(title: AppLocalizations.t('admin.search.title')),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _tabChip(colors, 0, AppLocalizations.t('admin.search.tab_users'))),
                        const SizedBox(width: 10),
                        Expanded(child: _tabChip(colors, 1, AppLocalizations.t('admin.search.tab_communities'))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: colors.glassFill,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.glassBorder),
                      ),
                      child: TextField(
                        controller: _controller,
                        style: TextStyle(color: colors.textPrimary, fontSize: 13.5),
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.search, color: colors.textMuted, size: 19),
                          hintText: _tab == 0
                              ? AppLocalizations.t('admin.search.hint_users')
                              : AppLocalizations.t('admin.search.hint_communities'),
                          hintStyle: TextStyle(color: colors.textMuted, fontSize: 13.5),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ComingSoonPlaceholder(
                  icon: Icons.search,
                  text: AppLocalizations.t('admin.search.empty'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabChip(AppPalette colors, int index, String label) {
    final selected = _tab == index;
    return GestureDetector(
      onTap: () => setState(() => _tab = index),
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