import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../deps.dart';
import '../edit_community_controller.dart';
import '../theme_draft.dart';
import 'color_picker_sheet.dart';
import 'ui.dart';


class ThemeCard extends StatelessWidget {
  const ThemeCard({super.key, required this.controller});
  final EditCommunityController controller;

  ThemeDraft get _d => controller.theme;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return ListenableBuilder(
      listenable: Listenable.merge([_d, controller.name]),
      builder: (context, _) {
        return SectionCard(
          title: AppLocalizations.t('admin.community.field_theme'),
          icon: Icons.palette_rounded,
          trailing: Switch(
            value: _d.enabled,
            activeThumbColor: colors.accentPrimary,
            onChanged: _d.setEnabled,
          ),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: !_d.enabled
                ? const SizedBox(width: double.infinity)
                : _d.loading
                    ? _loading(colors)
                    : _content(context, colors),
          ),
        );
      },
    );
  }

  Widget _loading(AppPalette colors) {
    return SizedBox(
      height: 220,
      width: double.infinity,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: colors.accentPrimary),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.t('admin.community.theme_loading'),
              style: TextStyle(color: colors.textMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context, AppPalette colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_d.loadError != null) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.orange.withValues(alpha: 0.12),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.orange, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.t('admin.community.theme_load_failed'),
                    style: TextStyle(color: colors.textMuted, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        _preview(colors),
        const SizedBox(height: 8),
        Center(
          child: Text(
            AppLocalizations.t('admin.community.theme_preview_hint'),
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.textMuted, fontSize: 12),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          AppLocalizations.t('admin.community.field_theme_color'),
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        _colorTile(context, colors),
        const SizedBox(height: 16),
        SwitchRow(
          icon: Icons.compress_rounded,
          label: AppLocalizations.t('admin.community.field_theme_compress'),
          value: _d.compress,
          onChanged: _d.setCompress,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.history_rounded, size: 14, color: colors.textMuted),
            const SizedBox(width: 6),
            Text(
              '${AppLocalizations.t('admin.community.theme_revision')}: '
              '${_d.currentRevision} → ${_d.currentRevision + 1}',
              style: TextStyle(color: colors.textMuted, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickColor(BuildContext context) async {
    final hex = await showColorPickerSheet(
      context,
      initialHex: _d.colorHex.isEmpty ? null : _d.colorHex,
    );
    if (hex != null) _d.setColor(hex);
  }

  Widget _colorTile(BuildContext context, AppPalette colors) {
    final hasColor = RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(_d.colorHex);
    final color = _themeColor(colors);

    return GestureDetector(
      onTap: () => _pickColor(context),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colors.glassFillStrong,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.glassBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hasColor ? _d.colorHex.toUpperCase() : '—',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            if (hasColor)
              GestureDetector(
                onTap: () => _d.setColor(''),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(Icons.close_rounded,
                      size: 18, color: colors.textMuted),
                ),
              ),
            Icon(Icons.colorize_rounded, size: 20, color: colors.textMuted),
          ],
        ),
      ),
    );
  }

  ImageProvider? _slotImage(XFile? picked, Uint8List? packBytes, bool removed) {
    if (picked != null) return FileImage(File(picked.path));
    if (removed) return null;
    if (packBytes != null && packBytes.isNotEmpty) return MemoryImage(packBytes);
    return null;
  }

  Color _themeColor(AppPalette colors) {
    if (RegExp(r'^#([0-9a-fA-F]{6})$').hasMatch(_d.colorHex)) {
      return Color(int.parse('FF${_d.colorHex.substring(1)}', radix: 16));
    }
    return colors.accentPrimary;
  }

  Widget _preview(AppPalette colors) {
    final themeColor = _themeColor(colors);

    final sidebarBg = _slotImage(
        _d.newBackground, _d.editor?.backgroundBytes, _d.removeBackground);
    final mainBg = _slotImage(_d.newTitlebarBg,
        _d.editor?.titlebarBackgroundBytes, _d.removeTitlebarBg);
    final sidebarLogo = _slotImage(
        _d.newTitlebar, _d.editor?.titlebarBytes, _d.removeTitlebar);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 300,
        decoration: BoxDecoration(
          border: Border.all(color: colors.glassBorder),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 110,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  GestureDetector(
                    onTap: controller.pickThemeBackground,
                    child: Container(
                      color: const Color(0xFF1A1A2E),
                      child: sidebarBg != null
                          ? Image(image: sidebarBg, fit: BoxFit.cover)
                          : null,
                    ),
                  ),
                  IgnorePointer(
                    child:
                        Container(color: Colors.black.withValues(alpha: 0.25)),
                  ),
                  Column(
                    children: [
                      GestureDetector(
                        onTap: controller.pickThemeTitlebar,
                        child: SizedBox(
                          height: 56,
                          width: double.infinity,
                          child: Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: sidebarLogo != null
                                    ? Image(
                                        image: sidebarLogo,
                                        fit: BoxFit.contain,
                                        width: double.infinity)
                                    : _emptySlot(
                                        Icons.title_rounded,
                                        AppLocalizations.t(
                                            'admin.community.field_theme_sidebar_logo'),
                                      ),
                              ),
                              if (sidebarLogo != null)
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: _deleteChip(_d.clearTitlebar),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (var i = 0; i < 3; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          child: IgnorePointer(
                            child: Container(
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ),
                        ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _editChip(
                            controller.pickThemeBackground,
                            AppLocalizations.t(
                                'admin.community.field_theme_sidebar_bg'),
                          ),
                          if (sidebarBg != null) ...[
                            const SizedBox(width: 4),
                            _deleteChip(_d.clearBackground),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: controller.pickThemeTitlebarBg,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: const Color(0xFF16213E),
                      child: mainBg != null
                          ? Image(image: mainBg, fit: BoxFit.cover)
                          : _emptySlot(
                              Icons.wallpaper_rounded,
                              AppLocalizations.t(
                                  'admin.community.field_theme_background'),
                            ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: IgnorePointer(
                        child: Container(
                          height: 140,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                themeColor.withValues(alpha: 0.0),
                                themeColor.withValues(alpha: 0.55),
                                themeColor,
                              ],
                            ),
                          ),
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                          alignment: Alignment.bottomLeft,
                          child: Text(
                            controller.name.text.isEmpty
                                ? 'Community'
                                : controller.name.text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _editChip(
                              controller.pickThemeTitlebarBg,
                              AppLocalizations.t(
                                  'admin.community.field_theme_background'),
                            ),
                            if (mainBg != null) ...[
                              const SizedBox(width: 4),
                              _deleteChip(_d.clearTitlebarBg),
                            ],
                          ],
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
    );
  }

  Widget _emptySlot(IconData icon, String label) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7), fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _editChip(VoidCallback onTap, String label) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.edit_rounded, color: Colors.white, size: 12),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 80),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _deleteChip(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
      ),
    );
  }
}