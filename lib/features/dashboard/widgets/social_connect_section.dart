import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/api/api_client.dart';
import '../../../core/widgets/social_logo_painters.dart';
import '../../../theme/viralcut_colors.dart';

class SocialConnectSection extends StatelessWidget {
  const SocialConnectSection({
    super.key,
    required this.links,
    this.onInstagramTap,
    this.onYouTubeTap,
    this.onXTap,
  });

  final SocialLinks links;
  final VoidCallback? onInstagramTap;
  final VoidCallback? onYouTubeTap;
  final VoidCallback? onXTap;

  bool get _allConnected => links.instagram && links.youtube && links.twitter;

  int get _missing =>
      (!links.instagram ? 1 : 0) +
      (!links.youtube ? 1 : 0) +
      (!links.twitter ? 1 : 0);

  VoidCallback? get _primaryAction {
    if (!links.instagram) return onInstagramTap;
    if (!links.youtube) return onYouTubeTap;
    return onXTap;
  }

  @override
  Widget build(BuildContext context) {
    if (_allConnected) return const SizedBox.shrink();
    final vc = ViralCutColors.of(context);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: _primaryAction,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: vc.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: vc.border),
          ),
          child: Row(
            children: [
              // Overlapping real platform logos
              _OverlappingLogos(links: links),
              const SizedBox(width: 14),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connect your socials',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: vc.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_missing platform${_missing > 1 ? 's' : ''} not linked',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: vc.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Connect pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Connect',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Three overlapping logo circles (real branding via shared painters)
class _OverlappingLogos extends StatelessWidget {
  const _OverlappingLogos({required this.links});

  final SocialLinks links;

  static const _size = 36.0;
  static const _overlap = 12.0;

  @override
  Widget build(BuildContext context) {
    final vc = ViralCutColors.of(context);
    final items = [
      (platform: 'instagram', connected: links.instagram),
      (platform: 'youtube', connected: links.youtube),
      (platform: 'twitter', connected: links.twitter),
    ];

    return SizedBox(
      width: _size + (_size - _overlap) * 2,
      height: _size,
      child: Stack(
        children: [
          for (var i = items.length - 1; i >= 0; i--)
            Positioned(
              left: i * (_size - _overlap),
              child: _LogoCircle(
                platform: items[i].platform,
                connected: items[i].connected,
                borderColor: vc.surface,
              ),
            ),
        ],
      ),
    );
  }
}

class _LogoCircle extends StatelessWidget {
  const _LogoCircle({
    required this.platform,
    required this.connected,
    required this.borderColor,
  });

  final String platform;
  final bool connected;
  final Color borderColor;

  static const _size = 36.0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: _size,
          height: _size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 2),
          ),
          child: ClipOval(
            child: ColorFiltered(
              colorFilter: connected
                  ? const ColorFilter.mode(Colors.transparent, BlendMode.saturation)
                  : const ColorFilter.matrix([
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0,      0,      0,      1, 0,
                    ]),
              child: SocialLogoBox(platform: platform, size: _size, radius: 0),
            ),
          ),
        ),
        if (connected)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E),
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: const Icon(Icons.check_rounded, size: 8, color: Colors.white),
            ),
          ),
      ],
    );
  }
}
