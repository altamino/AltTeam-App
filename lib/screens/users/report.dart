import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_snackbar.dart';

class UserReportsScreen extends StatefulWidget {
  const UserReportsScreen({super.key});

  @override
  State<UserReportsScreen> createState() => _UserReportsScreenState();
}

class _UserReportsScreenState extends State<UserReportsScreen> {
  int _activeTab = 0;

  final _targetController = TextEditingController();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _targetController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_targetController.text.trim().isEmpty || _reasonController.text.trim().isEmpty) {
      AppSnackbar.show(
        context,
        AppLocalizations.t('reports.write.fill_required'),
        type: SnackType.error,
      );
      return;
    }

    // TODO: отправка репорта на бэкенд.
    AppSnackbar.show(
      context,
      AppLocalizations.t('reports.write.not_ready'),
      type: SnackType.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors.bgGradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new, color: colors.textPrimary, size: 20),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.t('drawer.reports'),
                      style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          width: 340,
                          decoration: colors.glassCard(radius: 20),
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: colors.glassFillStrong,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: colors.glassBorder),
                                ),
                                child: Row(
                                  children: [
                                    _buildTabButton(AppLocalizations.t('reports.tab_write'), 0, colors),
                                    _buildTabButton(AppLocalizations.t('reports.tab_sent'), 1, colors),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),

                              if (_activeTab == 0) ...[
                                _buildIconBlock(Icons.edit_note_outlined, colors),
                                const SizedBox(height: 20),
                                Text(
                                  AppLocalizations.t('reports.write.title'),
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colors.textPrimary),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  AppLocalizations.t('reports.write.description'),
                                  style: TextStyle(fontSize: 13, color: colors.textMuted),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),

                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    AppLocalizations.t('reports.write.target_label'),
                                    style: TextStyle(color: colors.textMuted, fontSize: 12),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                _field(colors, _targetController, AppLocalizations.t('reports.write.target_hint')),

                                const SizedBox(height: 14),

                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    AppLocalizations.t('reports.write.reason_label'),
                                    style: TextStyle(color: colors.textMuted, fontSize: 12),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                _field(
                                  colors,
                                  _reasonController,
                                  AppLocalizations.t('reports.write.reason_hint'),
                                  maxLines: 4,
                                ),

                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  height: 44,
                                  child: DecoratedBox(
                                    decoration: colors.primaryButton(),
                                    child: TextButton(
                                      onPressed: _submit,
                                      style: TextButton.styleFrom(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      child: Text(
                                        AppLocalizations.t('reports.write.submit'),
                                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ),
                                ),
                              ] else ...[
                                _buildIconBlock(Icons.folder_open_outlined, colors),
                                const SizedBox(height: 20),
                                Text(
                                  AppLocalizations.t('reports.sent.title'),
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colors.textPrimary),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  AppLocalizations.t('reports.sent.empty'),
                                  style: TextStyle(fontSize: 13, color: colors.textMuted),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String text, int index, AppPalette colors) {
    final isSelected = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? colors.accentPrimary.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? colors.accentPrimary.withOpacity(0.3) : Colors.transparent,
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? colors.textPrimary : colors.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconBlock(IconData icon, AppPalette colors) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: colors.accentPrimary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentPrimary.withOpacity(0.25)),
      ),
      child: Icon(icon, color: colors.accentPrimary, size: 26),
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