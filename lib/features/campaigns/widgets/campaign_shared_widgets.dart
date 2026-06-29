import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/api/api_client.dart';
import '../../../core/campaign/media_url.dart';
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

/// Square cover for campaign list rows.
class CampaignListThumbnail extends StatelessWidget {
  const CampaignListThumbnail({
    super.key,
    required this.campaign,
    this.size = 96,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  final Campaign campaign;
  final double size;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final vc = ViralCutColors.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final coverUrl = resolveCampaignMediaUrl(campaign.coverImageUrl);

    final Widget image;
    if (coverUrl != null) {
      image = Image.network(
        coverUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _GradientCover(
          height: size,
          width: size,
          vc: vc,
          primary: primary,
        ),
      );
    } else {
      image = _GradientCover(
        height: size,
        width: size,
        vc: vc,
        primary: primary,
      );
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(width: size, height: size, child: image),
    );
  }
}

/// Square thumbnail for list rows (cover with logo / letter fallback).
class SquareMediaThumbnail extends StatelessWidget {
  const SquareMediaThumbnail({
    super.key,
    required this.size,
    this.imageUrl,
    this.fallbackImageUrl,
    this.fallbackLetter,
    this.borderRadius = BorderRadius.zero,
  });

  final double size;
  final String? imageUrl;
  final String? fallbackImageUrl;
  final String? fallbackLetter;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final vc = ViralCutColors.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final cover = resolveCampaignMediaUrl(imageUrl);
    final fallback = resolveCampaignMediaUrl(fallbackImageUrl);

    Widget image;
    if (cover != null) {
      image = Image.network(
        cover,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildFallback(
          context,
          vc: vc,
          primary: primary,
          networkUrl: fallback,
        ),
      );
    } else if (fallback != null) {
      image = Image.network(
        fallback,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            _gradientFallback(vc, primary, fallbackLetter),
      );
    } else {
      image = _gradientFallback(vc, primary, fallbackLetter);
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(width: size, height: size, child: image),
    );
  }

  Widget _buildFallback(
    BuildContext context, {
    required ViralCutColors vc,
    required Color primary,
    required String? networkUrl,
  }) {
    if (networkUrl != null) {
      return Image.network(
        networkUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            _gradientFallback(vc, primary, fallbackLetter),
      );
    }
    return _gradientFallback(vc, primary, fallbackLetter);
  }

  Widget _gradientFallback(
    ViralCutColors vc,
    Color primary,
    String? letter,
  ) {
    final displayLetter = (letter != null && letter.isNotEmpty)
        ? letter[0].toUpperCase()
        : '?';

    return Container(
      width: size,
      height: size,
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
      alignment: Alignment.center,
      child: Text(
        displayLetter,
        style: TextStyle(
          fontSize: size * 0.3,
          fontWeight: FontWeight.w800,
          color: Colors.white.withValues(alpha: 0.9),
        ),
      ),
    );
  }
}

class _GradientCover extends StatelessWidget {
  const _GradientCover({
    required this.height,
    required this.vc,
    required this.primary,
    this.width = double.infinity,
  });

  final double height;
  final double width;
  final ViralCutColors vc;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
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
  });

  final int poolPercent;
  final double minHeight;
  final bool showLabels;

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
                'Progress',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: vc.muted,
                ),
              ),
              Text(
                '$poolPercent% filled',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: vc.muted,
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
