import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/api/repositories/communities.dart';
import '../../../core/api/repositories/altacm.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/api/objects/args/roles.dart'; 
import '../../../core/storage.dart';

class AltAcmCommunityScreen extends StatefulWidget {
  final String ndcId;

  const AltAcmCommunityScreen({
    super.key, 
    required this.ndcId,
  });

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
      if (id == null) throw Exception(AppLocalizations.t('admin.community.invalid_id'));

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
                                  const SizedBox(height: 16),
                                  _buildAgentCard(colors),
                                  const SizedBox(height: 16),
                                  _buildMetaInfoCard(colors),
                                  const SizedBox(height: 24),
                                  _buildActionButtons(colors),
                                  const SizedBox(height: 24),
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
              _communityData?['name'] ?? AppLocalizations.t('admin.community.default_title'),
              style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainInfoCard(AppPalette colors) {
    final icon = _communityData?['icon'] as String?;
    final name = _communityData?['name'] ?? '';
    final tagline = _communityData?['tagline'] ?? '';

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
              if (tagline.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  tagline,
                  style: TextStyle(color: colors.textMuted, fontSize: 13, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ],
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
              _buildStatItem(colors, widget.ndcId, AppLocalizations.t('admin.community.ndc_id')),
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

  Widget _buildAgentCard(AppPalette colors) {
    final agent = _communityData?['agent'] as Map<String, dynamic>?;
    if (agent == null) return const SizedBox.shrink();

    final nickname = agent['nickname'] ?? AppLocalizations.t('admin.community.unknown_agent');
    final icon = agent['icon'] as String?;
    final level = agent['level'] ?? 0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          decoration: colors.glassCard(radius: 24),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.t('admin.community.agent_title'),
                style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: colors.accentPrimary.withOpacity(0.1),
                    backgroundImage: icon != null ? NetworkImage(icon) : null,
                    child: icon == null ? Icon(Icons.person, color: colors.accentPrimary) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nickname,
                          style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "${AppLocalizations.t('admin.community.level')} $level",
                          style: TextStyle(color: colors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaInfoCard(AppPalette colors) {
    final aminoId = _communityData?['endpoint'] ?? '';
    final lang = (_communityData?['primaryLanguage'] as String?)?.toUpperCase() ?? 'EN';
    final createdTimeStr = _communityData?['createdTime'] as String?;
    final listedStatus = _communityData?['listedStatus'] ?? 0;

    String formattedDate = AppLocalizations.t('common.unknown');
    if (createdTimeStr != null) {
      try {
        final parsedDate = DateTime.parse(createdTimeStr);
        formattedDate = DateFormat('dd.MM.yyyy HH:mm').format(parsedDate);
      } catch (_) {}
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          decoration: colors.glassCard(radius: 24),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMetaItem(colors, AppLocalizations.t('admin.community.amino_id'), "@$aminoId"),
              _buildMetaItem(colors, AppLocalizations.t('admin.community.primary_lang'), lang),
              _buildMetaItem(colors, AppLocalizations.t('admin.community.created_at'), formattedDate),
              _buildMetaItem(
                colors, 
                AppLocalizations.t('admin.community.visibility_status'), 
                listedStatus == 2 
                    ? AppLocalizations.t('admin.community.status_listed') 
                    : AppLocalizations.t('admin.community.status_unlisted'),
                isLast: true
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaItem(AppPalette colors, String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(color: colors.textMuted, fontSize: 14)),
              Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
          if (!isLast) ...[
            const SizedBox(height: 12),
            Divider(color: colors.textMuted.withOpacity(0.1), height: 1),
          ]
        ],
      ),
    );
  }

  Widget _buildActionButtons(AppPalette colors) {
    final isStaff = RoleTypes.isStaffRole(Storage.role);

    final editButton = ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.accentPrimary.withOpacity(0.15),
        foregroundColor: colors.accentPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      icon: const Icon(Icons.edit_outlined, size: 20),
      label: Text(AppLocalizations.t('common.edit'), style: const TextStyle(fontWeight: FontWeight.bold)),
      onPressed: () {
        context.push("/altacm/edit", extra: _communityData);
      },
    );

    return Column(
      children: [
        if (isStaff)
          Row(
            children: [
              Expanded(child: editButton),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.textMuted.withOpacity(0.1),
                    foregroundColor: colors.textPrimary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.visibility_off_outlined, size: 20),
                  label: Text(AppLocalizations.t('common.disable'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    AppSnackbar.show(context, AppLocalizations.t('admin.community.disable_unavailable'), type: SnackType.info);
                  },
                ),
              ),
            ],
          )
        else
          SizedBox(
            width: double.infinity,
            child: editButton,
          ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: colors.error,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: colors.error.withOpacity(0.3)),
              ),
            ),
            icon: const Icon(Icons.delete_outline, size: 20),
            label: Text(AppLocalizations.t('ndc.details.delete'), style: const TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () => _showDeleteDialog(colors),
          ),
        ),
      ],
    );
  }

  EdgeInsetsGeometry pastures(double value) => EdgeInsets.only(bottom: value);
}