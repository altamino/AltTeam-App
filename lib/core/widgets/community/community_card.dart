import 'dart:ui';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';


class CommunityCard extends StatelessWidget {
  const CommunityCard({super.key, required this.community, required this.onTap});

  final Map<String, dynamic> community;
  final VoidCallback onTap;

  static String? coverUrl(Map<String, dynamic> c) {
    final promo = c['promotionalMediaList'];
    if (promo is List && promo.isNotEmpty) {
      final first = promo.first;
      if (first is List && first.length > 1 && first[1] is String) {
        final url = first[1] as String;
        if (url.startsWith('http')) return url;
      }
    }
    for (final key in ['coverUrl', 'cover']) {
      final v = c[key];
      if (v is String && v.startsWith('http')) return v;
    }
    return null;
  }
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final name = (community['name'] ?? '').toString();
    final icon = community['icon'] as String?;
    final members = community['membersCount'] ?? 0;
    final cover = coverUrl(community);
    const radius = BorderRadius.all(Radius.circular(20));

    return Container(
      height: 136,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(color: colors.shadow, blurRadius: 20, offset: const Offset(0, 6)),
        ],
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: colors.glassBorder),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _Cover(url: cover, icon: icon, colors: colors),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0xB3000000)],
                  stops: [0.35, 1],
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 10,
              bottom: 12,
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(13.5),
                      child: icon != null
                          ? Image.network(
                              icon,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stack) =>
                                  _IconFallback(colors: colors),
                            )
                          : _IconFallback(colors: colors),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$members ${AppLocalizations.t('admin.community.members')}',
                          style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Color(0xCCFFFFFF)),
                ],
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(onTap: onTap),
            ),
          ],
        ),
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.url, required this.icon, required this.colors});
  final String? url;
  final String? icon;
  final AppPalette colors;

  @override
  Widget build(BuildContext context) {
    final gradient = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.accentPrimaryDim, colors.accentPrimary],
        ),
      ),
    );

    if (url != null) {
      return Image.network(
        url!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => gradient,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : gradient,
      );
    }

    if (icon != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          gradient,
          ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: 22,
              sigmaY: 22,
              tileMode: TileMode.mirror,
            ),
            child: Transform.scale(
              scale: 1.5,
              child: Image.network(
                icon!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => const SizedBox.shrink(),
              ),
            ),
          ),
          ColoredBox(color: colors.accentPrimaryDim.withValues(alpha: 0.35)),
        ],
      );
    }

    return gradient;
  }
}

class _IconFallback extends StatelessWidget {
  const _IconFallback({required this.colors});
  final AppPalette colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colors.surfaceElevated,
      child: Icon(Icons.groups_outlined, color: colors.accentPrimary),
    );
  }
}