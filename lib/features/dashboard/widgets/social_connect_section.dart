import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/api/api_client.dart';
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
    if (links.instagram && links.youtube) {
      return const SizedBox.shrink();
    }

    final vc = ViralCutColors.of(context);
    final needsInstagram = !links.instagram;
    final needsYouTube = !links.youtube;

    return Material(
      color: vc.primary.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: needsInstagram ? onInstagramTap : onYouTubeTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: vc.primary.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              _CompactSocialIcons(
                showInstagram: needsInstagram,
                showYouTube: needsYouTube,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  needsInstagram && needsYouTube
                      ? 'Link Instagram & YouTube for more campaigns'
                      : needsInstagram
                          ? 'Link Instagram to unlock campaigns'
                          : 'Link YouTube to unlock campaigns',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: vc.onSurface,
                    height: 1.25,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, size: 20, color: vc.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactSocialIcons extends StatelessWidget {
  const _CompactSocialIcons({
    required this.showInstagram,
    required this.showYouTube,
  });

  final bool showInstagram;
  final bool showYouTube;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showInstagram) ...[
          const _MiniSocialBadge(
            icon: Icons.camera_alt,
            color: Color(0xFFE1306C),
          ),
          if (showYouTube) const SizedBox(width: 4),
        ],
        if (showYouTube)
          const _MiniSocialBadge(
            icon: Icons.play_arrow,
            color: Color(0xFFEF4444),
          ),
      ],
    );
  }
}

class _MiniSocialBadge extends StatelessWidget {
  const _MiniSocialBadge({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final vc = ViralCutColors.of(context);
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: vc.border),
      ),
      child: Icon(icon, color: color, size: 14),
    );
  }
}
