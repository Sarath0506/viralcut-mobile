import 'package:flutter/material.dart';

/// Round ViralCut app icon for auth screens (Stitch-style header).
class AuthAppIcon extends StatelessWidget {
  const AuthAppIcon({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.28),
        child: Image.asset(
          'assets/images/viralcut_app_icon.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
