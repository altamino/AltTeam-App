import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_snackbar.dart';

class AltAcmEditCommunityScreen extends StatefulWidget {
  final Map<String, dynamic>? communityData;

  const AltAcmEditCommunityScreen({
    super.key,
    this.communityData,
  });

  @override
  State<AltAcmEditCommunityScreen> createState() => _AltAcmEditCommunityScreenState();
}

class _AltAcmEditCommunityScreenState extends State<AltAcmEditCommunityScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _taglineController;
  late TextEditingController _aminoIdController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Инициализируем контроллеры переданными данными или пустыми строками
    _nameController = TextEditingController(text: widget.communityData?['name'] ?? '');
    _taglineController = TextEditingController(text: widget.communityData?['tagline'] ?? '');
    _aminoIdController = TextEditingController(text: widget.communityData?['endpoint'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _taglineController.dispose();
    _aminoIdController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      // Имитация запроса к API
      await Future.delayed(const Duration(seconds: 1));
      
      if (!mounted) return;
      
      AppSnackbar.show(
        context, 
        AppLocalizations.t('admin.community.save_success'), 
        type: SnackType.success,
      );
      
      // Возвращаемся назад и передаем true, чтобы предыдущий экран обновился
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(context, e.toString(), type: SnackType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
              _buildAppBar(colors),
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator(color: colors.accentPrimary))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _buildFormCard(colors),
                              const SizedBox(height: 24),
                              _buildSubmitButton(colors),
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

  Widget _buildAppBar(AppPalette colors) {
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
              AppLocalizations.t('admin.community.edit_title'),
              style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(AppPalette colors) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: colors.glassCard(radius: 24),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Поле: Название
              Text(
                AppLocalizations.t('admin.community.field_name'),
                style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: AppLocalizations.t('admin.community.field_name_hint'),
                  hintStyle: TextStyle(color: colors.textMuted),
                ),
                validator: (val) => val == null || val.trim().isEmpty 
                    ? AppLocalizations.t('admin.community.err_empty') 
                    : null,
              ),
              const SizedBox(height: 20),

              // Поле: Слоган
              Text(
                AppLocalizations.t('admin.community.field_tagline'),
                style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _taglineController,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: AppLocalizations.t('admin.community.field_tagline_hint'),
                  hintStyle: TextStyle(color: colors.textMuted),
                ),
              ),
              const SizedBox(height: 20),

              // Поле: Amino ID (Endpoint)
              Text(
                AppLocalizations.t('admin.community.field_amino_id'),
                style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _aminoIdController,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: AppLocalizations.t('admin.community.field_amino_id_hint'),
                  hintStyle: TextStyle(color: colors.textMuted),
                  prefixText: '@',
                  prefixStyle: TextStyle(color: colors.accentPrimary),
                ),
                validator: (val) => val == null || val.trim().isEmpty 
                    ? AppLocalizations.t('admin.community.err_empty') 
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(AppPalette colors) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.accentPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        icon: const Icon(Icons.save_rounded, size: 20),
        label: Text(
          AppLocalizations.t('common.save'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        onPressed: _saveChanges,
      ),
    );
  }
}