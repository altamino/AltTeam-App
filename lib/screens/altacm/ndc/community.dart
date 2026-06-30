import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/api/repositories/communities.dart';
import '../../../core/api/repositories/altacm.dart';
import '../../../core/widgets/app_snackbar.dart';

class AltAcmCommunityScreen extends StatefulWidget {
  final String ndcId;

  const AltAcmCommunityScreen({super.key, required this.ndcId});

  @override
  State<AltAcmCommunityScreen> createState() => _AltAcmCommunityScreenState();
}

class _AltAcmCommunityScreenState extends State<AltAcmCommunityScreen> {
  final _comRepo = CommunitiesRepository();
  final _altAcmRepo = AltACMRepository();
  Map<String, dynamic>? _communityData;
  bool _isLoading = true;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadCommunityInfo();
  }

  Future<void> _loadCommunityInfo() async {
    setState(() => _isLoading = true);
    try {
      final id = int.tryParse(widget.ndcId);
      if (id == null) throw Exception("Invalid Community ID");

      final res = await _comRepo.getCommunityInfo(id);
      if (!mounted) return;

      setState(() {
        _communityData = res['community'];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppSnackbar.show(context, e.toString(), type: SnackType.error);
    }
  }

  Future<void> _deleteCommunity() async {
    final id = int.tryParse(widget.ndcId);
    if (id == null) return;

    setState(() => _isDeleting = true);
    try {
      await _altAcmRepo.deleteCommunity(id);
      if (!mounted) return;
      AppSnackbar.show(context, AppLocalizations.t('ndc.details.deleted_success'));
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      AppSnackbar.show(context, e.toString(), type: SnackType.error);
    }
  }

  void _showDeleteDialog(AppPalette colors) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: colors.glassFillStrong,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            AppLocalizations.t('ndc.details.delete_dialog_title'),
            style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: Text(
            AppLocalizations.t('ndc.details.delete_dialog_message'),
            style: TextStyle(color: colors.textMuted, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: Text(
                AppLocalizations.t('common.cancel'),
                style: TextStyle(color: colors.textMuted),
              ),
            ),
            TextButton(
              onPressed: () {
                context.pop();
                _deleteCommunity();
              },
              child: Text(
                AppLocalizations.t('ndc.details.delete'),
                style: TextStyle(color: colors.error, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
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
              _buildAppBar(context, colors),
              Expanded(
                child: _isLoading || _isDeleting
                    ? Center(child: CircularProgressIndicator(color: colors.accentPrimary))
                    : _communityData == null
                        ? Center(child: Text(AppLocalizations.t('common.error'), style: TextStyle(color: colors.textMuted)))
                        : RefreshIndicator(
                            onRefresh: _loadCommunityInfo,
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  _buildMainInfoCard(colors),
                                  const SizedBox(height: 16),
                                  _buildStatsCard(colors),
                                ],
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

  Widget _buildAppBar(BuildContext context, AppPalette colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: colors.textPrimary, size: 20),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _communityData?['name'] ?? 'Community',
              style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_communityData != null && !_isDeleting)
            IconButton(
              icon: Icon(Icons.delete_outline, color: colors.error, size: 22),
              onPressed: () => _showDeleteDialog(colors),
            ),
        ],
      ),
    );
  }

  Widget _buildMainInfoCard(AppPalette colors) {
    final icon = _communityData?['icon'] as String?;
    final name = _communityData?['name'] ?? '';
    final aminoId = _communityData?['endpoint'] ?? '';
    final lang = (_communityData?['lang'] as String?)?.toUpperCase() ?? 'EN';

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          decoration: colors.glassCard(radius: 24),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: icon != null
                    ? Image.network(icon, width: 90, height: 90, fit: BoxFit.cover)
                    : Container(
                        width: 90,
                        height: 90,
                        color: colors.accentPrimary.withOpacity(0.12),
                        child: Icon(Icons.groups_outlined, size: 42, color: colors.accentPrimary),
                      ),
              ),
              const SizedBox(height: 16),
              Text(
                name,
                style: TextStyle(color: colors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '@$aminoId',
                style: TextStyle(color: colors.textMuted, fontSize: 14),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.accentPrimary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  lang,
                  style: TextStyle(color: colors.accentPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(AppPalette colors) {
    final members = _communityData?['membersCount'] ?? 0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          decoration: colors.glassCard(radius: 24),
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(colors, members.toString(), AppLocalizations.t('admin.community.members')),
              _buildStatItem(colors, widget.ndcId, "ID"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(AppPalette colors, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: colors.textMuted, fontSize: 13),
        ),
      ],
    );
  }
}