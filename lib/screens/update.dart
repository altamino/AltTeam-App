import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api/constants.dart';
import '../core/l10n/app_localizations.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/app_background.dart';
import '../core/widgets/primary_button.dart';

class UpdateRequiredPage extends StatefulWidget {
  const UpdateRequiredPage({
    super.key,
    required this.downloadPage,
    this.latestVersion,
  });

  final String downloadPage;
  final String? latestVersion;

  @override
  State<UpdateRequiredPage> createState() => _UpdateRequiredPageState();
}

class _UpdateRequiredPageState extends State<UpdateRequiredPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openDownloadPage() async {
    if (_opening) return;
    setState(() => _opening = true);

    final url = widget.downloadPage.isNotEmpty ? widget.downloadPage : altTeamPage;
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final version = widget.latestVersion;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Badge(accent: colors.accentPrimary),
                        const SizedBox(height: 28),
                        Text(
                          AppLocalizations.t('update_required_title'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          AppLocalizations.t('update_required_message'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 32),
                        PrimaryButton(
                          label: AppLocalizations.t('update_required_button'),
                          height: 52,
                          radius: 14,
                          loading: _opening,
                          onPressed: _openDownloadPage,
                        ),
                        if (version != null && version.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          Text(
                            'v$version',
                            style: TextStyle(
                              color: colors.textMuted,
                              fontSize: 12,
                              letterSpacing: 0.4,
                            ),
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
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.10),
            ),
          ),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.16),
              border: Border.all(color: accent.withValues(alpha: 0.40), width: 1.2),
            ),
            child: Icon(Icons.system_update_alt_rounded, color: accent, size: 32),
          ),
        ],
      ),
    );
  }
}
