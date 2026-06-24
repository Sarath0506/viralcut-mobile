import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/api/api_client.dart';
import '../../../core/layout/app_spacing.dart';
import '../../../theme/viralcut_colors.dart';

class SocialConnectSection extends StatelessWidget {
  const SocialConnectSection({
    super.key,
    required this.links,
    this.onInstagramTap,
    this.onYouTubeTap,
  });

  final SocialLinks links;
  final VoidCallback? onInstagramTap;
  final VoidCallback? onYouTubeTap;

  @override
  Widget build(BuildContext context) {
    final vc = ViralCutColors.of(context);
    final VoidCallback? onTap = (!links.instagram && onInstagramTap != null)
        ? onInstagramTap
        : onYouTubeTap;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: vc.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: vc.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SocialIconStack(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        'Connect your socials',
                        maxLines: 2,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: vc.onSurface,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: onTap,
                      style: FilledButton.styleFrom(
                        backgroundColor: vc.primary,
                        minimumSize: const Size(92, AppSpacing.minTouchTarget),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Connect',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Link Instagram and YouTube to unlock more campaigns.',
                  maxLines: 2,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: vc.muted,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialIconStack extends StatelessWidget {
  const _SocialIconStack();

  @override
  Widget build(BuildContext context) {
    final vc = ViralCutColors.of(context);

    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: _SocialBadge(
              icon: Icons.camera_alt,
              color: const Color(0xFFE1306C),
              borderColor: vc.primary.withValues(alpha: 0.12),
              shadowColor: vc.onSurface.withValues(alpha: 0.05),
              surfaceColor: vc.surface,
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: _SocialBadge(
              icon: Icons.play_arrow,
              color: const Color(0xFFEF4444),
              borderColor: vc.primary.withValues(alpha: 0.12),
              shadowColor: vc.onSurface.withValues(alpha: 0.05),
              surfaceColor: vc.surface,
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialBadge extends StatelessWidget {
  const _SocialBadge({
    required this.icon,
    required this.color,
    required this.borderColor,
    required this.shadowColor,
    required this.surfaceColor,
  });

  final IconData icon;
  final Color color;
  final Color borderColor;
  final Color shadowColor;
  final Color surfaceColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }
}