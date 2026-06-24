import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/api/api_client.dart';
import '../../../core/campaign/media_url.dart';
import '../../../core/format/money_format.dart';
import '../../../theme/viralcut_colors.dart';

class CampaignBrandAvatar extends StatelessWidget {
  const CampaignBrandAvatar({
    super.key,
    required this.campaign,
    this.radius = 18,
  });

  final Campaign campaign;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final logoUrl = resolveCampaignMediaUrl(campaign.brandLogoUrl);

    if (logoUrl != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: ViralCutColors.of(context).surface,
        backgroundImage: NetworkImage(logoUrl),
      );
    }

    final letter = campaign.displayBrand.isNotEmpty
        ? campaign.displayBrand[0].toUpperCase()
        : '?';
    return CircleAvatar(
      radius: radius,
      backgroundColor: primary.withValues(alpha: 0.12),
      child: Text(
        letter,
        style: TextStyle(
          color: primary,
          fontWeight: FontWeight.w800,
          fontSize: radius * 0.85,
        ),
      ),
    );
  }
}

class CampaignCoverImage extends StatelessWidget {
  const CampaignCoverImage({
    super.key,
    required this.campaign,
    required this.height,
    this.borderRadius = const BorderRadius.vertical(top: Radius.circular(16)),
  });

  final Campaign campaign;
  final double height;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final vc = ViralCutColors.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final coverUrl = resolveCampaignMediaUrl(campaign.coverImageUrl);

    if (coverUrl != null) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: Image.network(
          coverUrl,
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              _GradientCover(height: height, vc: vc, primary: primary),
        ),
      );
    }

    return _GradientCover(height: height, vc: vc, primary: primary);
  }
}

class _GradientCover extends StatelessWidget {
  const _GradientCover({
    required this.height,
    required this.vc,
    required this.primary,
  });

  final double height;
  final ViralCutColors vc;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary.withValues(alpha: 0.35),
            vc.deepSurface.withValues(alpha: 0.85),
          ],
        ),
      ),
    );
  }
}

class CampaignPoolBar extends StatelessWidget {
  const CampaignPoolBar({
    super.key,
    required this.poolPercent,
    this.minHeight = 5,
    this.showLabels = false,
    this.remainingPaise,
  });

  final int poolPercent;
  final double minHeight;
  final bool showLabels;
  final int? remainingPaise;

  @override
  Widget build(BuildContext context) {
    final vc = ViralCutColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showLabels) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Availability',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: vc.muted,
                ),
              ),
              if (remainingPaise != null)
                Text(
                  '${formatPaise(remainingPaise!)} left',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: vc.money,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: poolPercent / 100,
            minHeight: minHeight,
            backgroundColor: vc.surfaceVariant,
            color: vc.moneyBright,
          ),
        ),
        if (showLabels) ...[
          const SizedBox(height: 4),
          Text(
            '$poolPercent% claimed',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: vc.muted,
            ),
          ),
        ],
      ],
    );
  }
}

class CampaignPlatformChip extends StatelessWidget {
  const CampaignPlatformChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final vc = ViralCutColors.of(context);
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: vc.onSurface,
        ),
      ),
    );
  }
}
