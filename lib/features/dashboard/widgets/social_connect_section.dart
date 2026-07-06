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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary.withValues(alpha: 0.08),
            primary.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primary.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SocialBadge(type: _SocialType.instagram, connected: links.instagram),
              const SizedBox(width: 10),
              _SocialBadge(type: _SocialType.youtube, connected: links.youtube),
              const SizedBox(width: 10),
              _SocialBadge(type: _SocialType.x, connected: links.twitter),
              const Spacer(),
              Icon(Icons.link_rounded, size: 18, color: primary.withValues(alpha: 0.4)),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Connect your socials',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: vc.onSurface,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _subtitle,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: vc.muted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _primaryAction,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                'Connect  →',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
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

class _SocialBadge extends StatelessWidget {
  const _SocialBadge({required this.type, required this.connected});

  final _SocialType type;
  final bool connected;

  @override
  Widget build(BuildContext context) {
    final vc = ViralCutColors.of(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(11),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          foregroundDecoration: connected
              ? BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(11),
                )
              : null,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: _iconForType(type),
          ),
        ),
        if (connected)
          Positioned(
            right: -3,
            bottom: -3,
            child: Container(
              padding: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(
                color: vc.background,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                size: 15,
                color: vc.moneyBright,
              ),
            ),
          ),
      ],
    );
  }

  Widget _iconForType(_SocialType type) {
    switch (type) {
      case _SocialType.instagram:
        return CustomPaint(
          painter: _InstagramPainter(),
          child: const SizedBox(width: 40, height: 40),
        );
      case _SocialType.youtube:
        return CustomPaint(
          painter: _YouTubePainter(),
          child: const SizedBox(width: 40, height: 40),
        );
      case _SocialType.x:
        return Container(
          color: Colors.black,
          alignment: Alignment.center,
          child: const Text(
            '𝕏',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
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
      Rect.fromCenter(center: Offset(cx, cy), width: 17, height: 17),
      const Radius.circular(5),
    );
    canvas.drawRRect(rrect, iconPaint);

    // Circle
    canvas.drawCircle(Offset(cx, cy), 5.2, iconPaint);

    // Dot top-right
    canvas.drawCircle(
      Offset(cx + 6.5, cy - 6.5),
      1.3,
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
        Rect.fromCenter(center: Offset(cx, cy), width: 24, height: 16),
        const Radius.circular(4),
      ),
      rrectPaint,
    );

    // Red play triangle
    final triPaint = Paint()
      ..color = const Color(0xFFFF0000)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(cx - 4.5, cy - 5.5)
      ..lineTo(cx + 6.5, cy)
      ..lineTo(cx - 4.5, cy + 5.5)
      ..close();
    canvas.drawPath(path, triPaint);
  }

  @override
  bool shouldRepaint(_) => false;
}
