import 'package:flutter/material.dart';

class InstagramPainter extends CustomPainter {
  const InstagramPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFF9CE34), Color(0xFFEE2A7B), Color(0xFF6228D7)],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ).createShader(rect),
    );
    final cx = size.width / 2;
    final cy = size.height / 2;
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.055
      ..strokeCap = StrokeCap.round;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(cx, cy),
            width: size.width * 0.52,
            height: size.height * 0.52),
        Radius.circular(size.width * 0.14),
      ),
      stroke,
    );
    canvas.drawCircle(Offset(cx, cy), size.width * 0.155, stroke);
    canvas.drawCircle(
      Offset(cx + size.width * 0.175, cy - size.height * 0.175),
      size.width * 0.042,
      stroke..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

class YouTubePainter extends CustomPainter {
  const YouTubePainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Offset.zero & size, Paint()..color = const Color(0xFFFF0000));
    final cx = size.width / 2;
    final cy = size.height / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(cx, cy),
            width: size.width * 0.62,
            height: size.height * 0.44),
        Radius.circular(size.width * 0.1),
      ),
      Paint()..color = Colors.white,
    );
    final tri = Path()
      ..moveTo(cx - size.width * 0.10, cy - size.height * 0.14)
      ..lineTo(cx + size.width * 0.16, cy)
      ..lineTo(cx - size.width * 0.10, cy + size.height * 0.14)
      ..close();
    canvas.drawPath(tri, Paint()..color = const Color(0xFFFF0000));
  }

  @override
  bool shouldRepaint(_) => false;
}

class XPainter extends CustomPainter {
  const XPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Offset.zero & size, Paint()..color = const Color(0xFF000000));
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = size.width * 0.085
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final p = size.width * 0.24;
    final q = size.width * 0.76;
    canvas.drawLine(Offset(p, p), Offset(q, q), paint);
    canvas.drawLine(Offset(q, p), Offset(p, q), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

/// A rounded square widget that renders a social platform logo.
class SocialLogoBox extends StatelessWidget {
  const SocialLogoBox({
    super.key,
    required this.platform,
    required this.size,
    this.radius,
  });

  final String platform;
  final double size;
  final double? radius;

  CustomPainter get _painter => switch (platform) {
        'youtube' => const YouTubePainter(),
        'twitter' => const XPainter(),
        _ => const InstagramPainter(),
      };

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius ?? size * 0.22),
      child: CustomPaint(
        painter: _painter,
        size: Size(size, size),
        child: SizedBox(width: size, height: size),
      ),
    );
  }
}
