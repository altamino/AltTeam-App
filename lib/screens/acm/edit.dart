import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'edit/deps.dart';
import 'edit/edit_community_controller.dart';
import 'edit/edit_tab.dart';
import 'edit/tabs/content_tab.dart';
import 'edit/tabs/general_tab.dart';
import 'edit/tabs/media_tab.dart';
import 'edit/tabs/members_tab.dart';

class AltAcmEditCommunityScreen extends StatefulWidget {
  const AltAcmEditCommunityScreen({super.key, required this.ndcId});

  final int ndcId;

  @override
  State<AltAcmEditCommunityScreen> createState() =>
      _AltAcmEditCommunityScreenState();
}

class _AltAcmEditCommunityScreenState extends State<AltAcmEditCommunityScreen>
    with SingleTickerProviderStateMixin {
  static const List<EditTab> _tabs = [
    GeneralTab(),
    MediaTab(),
    ContentTab(),
    MembersTab(),
  ];

  late final EditCommunityController _c;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _c = EditCommunityController(widget.ndcId)..notify = _snack;
    _tabController = TabController(length: _tabs.length, vsync: this)
      ..addListener(() {
        if (mounted) setState(() {});
      });
    _c.load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _c.dispose();
    super.dispose();
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    AppSnackbar.show(context, msg,
        type: error ? SnackType.error : SnackType.success);
  }

  Future<void> _save() async {
    if (_c.saving) return;

    if (!(_c.formKey.currentState?.validate() ?? false)) {
      final i = _tabs.indexWhere((t) => t.id == 'general');
      if (i >= 0 && _tabController.index != i) _tabController.animateTo(i);
      return;
    }
    FocusScope.of(context).unfocus();

    final ok = await _c.save();
    if (!mounted || !ok) return;
    _snack(AppLocalizations.t('admin.community.save_success'));
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.pop(_c.dataChanged);
      },
      child: Scaffold(
        body: AppBackground(
          child: SafeArea(
            bottom: false,
            child: ListenableBuilder(
              listenable: _c,
              builder: (context, _) {
                final ready = !_c.loading && _c.loadError == null;
                final showSave =
                    ready && _tabs[_tabController.index].showSaveBar;

                return Column(
                  children: [
                    AdminHeader(
                      title: AppLocalizations.t('admin.community.edit_title'),
                    ),
                    if (ready) _buildTabBar(colors),
                    Expanded(child: _buildBody(colors)),
                    if (showSave) _buildSaveBar(colors),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar(AppPalette colors) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.glassFill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.glassBorder),
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        splashBorderRadius: BorderRadius.circular(14),
        labelPadding: EdgeInsets.zero,
        indicator: BoxDecoration(
          color: colors.accentPrimary.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: colors.accentPrimary.withValues(alpha: 0.45)),
        ),
        tabs: [
          for (var i = 0; i < _tabs.length; i++)
            Tab(
              height: 40,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _tabs[i].icon,
                    size: 19,
                    color: _tabController.index == i
                        ? colors.accentPrimary
                        : colors.textMuted,
                  ),
                  if (_tabController.index == i) ...[
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        AppLocalizations.t(_tabs[i].titleKey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(AppPalette colors) {
    if (_c.loading) {
      return Center(
          child: CircularProgressIndicator(color: colors.accentPrimary));
    }
    if (_c.loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 40, color: colors.error),
              const SizedBox(height: 12),
              Text(_c.loadError!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.error)),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _c.load,
                child: Text(AppLocalizations.t('common.retry'),
                    style: TextStyle(color: colors.accentPrimary)),
              ),
            ],
          ),
        ),
      );
    }

    return Form(
      key: _c.formKey,
      child: TabBarView(
        controller: _tabController,
        children: [
          for (final tab in _tabs)
            ListenableBuilder(
              listenable: _c,
              builder: (context, _) => tab.build(context, _c),
            ),
        ],
      ),
    );
  }

  Widget _buildSaveBar(AppPalette colors) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: colors.glassFillStrong,
        border: Border(top: BorderSide(color: colors.glassBorder)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: _c.saving ? null : _save,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: colors.accentPrimary,
            disabledBackgroundColor:
                colors.accentPrimary.withValues(alpha: 0.5),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          icon: _c.saving
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: colors.onAccent),
                )
              : Icon(Icons.check_rounded, size: 22, color: colors.onAccent),
          label: Text(
            AppLocalizations.t('common.save'),
            style: TextStyle(
              color: colors.onAccent,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}