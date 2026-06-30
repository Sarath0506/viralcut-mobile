import 'dart:math' as math;

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
    this.onXTap,
  });

  final SocialLinks links;
  final VoidCallback? onInstagramTap;
  final VoidCallback? onYouTubeTap;
  final VoidCallback? onXTap;

  bool get _allConnected => links.instagram && links.youtube && links.twitter;

  String get _subtitle {
    final missing = <String>[];
    if (!links.instagram) missing.add('Instagram');
    if (!links.youtube) missing.add('YouTube');
    if (!links.twitter) missing.add('X');
    if (missing.length == 1) return 'Link ${missing[0]} to unlock more campaigns.';
    final last = missing.removeLast();
    return 'Link ${missing.join(', ')} & $last to unlock more campaigns and earn more.';
  }

  VoidCallback? get _primaryAction {
    if (!links.instagram) return onInstagramTap;
    if (!links.youtube) return onYouTubeTap;
    return onXTap;
  }

  @override
  Widget build(BuildContext context) {
    if (_allConnected) return const SizedBox.shrink();

    final vc = ViralCutColors.of(context);
    final primary = Theme.of(context).colorScheme.primary;

    final missingIcons = <_SocialType>[];
    if (!links.instagram) missingIcons.add(_SocialType.instagram);
    if (!links.youtube) missingIcons.add(_SocialType.youtube);
    if (!links.twitter) missingIcons.add(_SocialType.x);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Social icons — horizontal row to keep card compact
          _SocialIconsRow(types: missingIcons),
          const SizedBox(width: 12),
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
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: vc.muted,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: FilledButton(
              onPressed: _primaryAction,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 11),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                'Connect  →',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _SocialType { instagram, youtube, x }

class _SocialIconsRow extends StatelessWidget {
  const _SocialIconsRow({required this.types});
  final List<_SocialType> types;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < types.length; i++) ...[
          _SocialBadge(type: types[i]),
          if (i < types.length - 1) const SizedBox(height: 5),
        ],
      ],
    );
  }
}

class _SocialBadge extends StatelessWidget {
  const _SocialBadge({required this.type});
  final _SocialType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: _iconForType(type),
      ),
    );
  }

  Widget _iconForType(_SocialType type) {
    switch (type) {
      case _SocialType.instagram:
        return CustomPaint(
          painter: _InstagramPainter(),
          child: const SizedBox(width: 36, height: 36),
        );
      case _SocialType.youtube:
        return CustomPaint(
          painter: _YouTubePainter(),
          child: const SizedBox(width: 36, height: 36),
        );
      case _SocialType.x:
        return Container(
          color: Colors.black,
          alignment: Alignment.center,
          child: const Text(
            '𝕏',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        );
    }
  }
}

// Instagram gradient background + camera outline
class _InstagramPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Gradient background
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFF9CE34),
          Color(0xFFEE2A7B),
          Color(0xFF6228D7),
        ],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    final cx = size.width / 2;
    final cy = size.height / 2;
    final iconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Outer rounded square
    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy), width: 16, height: 16),
      const Radius.circular(4),
    );
    canvas.drawRRect(rrect, iconPaint);

    // Circle
    canvas.drawCircle(Offset(cx, cy), 4.8, iconPaint);

    // Dot top-right
    canvas.drawCircle(
      Offset(cx + 6, cy - 6),
      1.2,
      iconPaint..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

// YouTube red background + white play triangle
class _YouTubePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFFF0000));

    final cx = size.width / 2;
    final cy = size.height / 2;

    // White rounded rectangle (YouTube logo shape)
    final rrectPaint = Paint()..color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: 22, height: 15),
        const Radius.circular(4),
      ),
      rrectPaint,
    );

    // Red play triangle
    final triPaint = Paint()
      ..color = const Color(0xFFFF0000)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(cx - 4, cy - 5)
      ..lineTo(cx + 6, cy)
      ..lineTo(cx - 4, cy + 5)
      ..close();
    canvas.drawPath(path, triPaint);
  }

  @override
  bool shouldRepaint(_) => false;
}
