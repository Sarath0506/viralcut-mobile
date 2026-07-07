import 'package:flutter/material.dart';

import '../../../theme/halchal_colors.dart';

/// Branded Halchal app icon with size variants for splash, auth, and headers.
class AuthAppIcon extends StatelessWidget {
  const AuthAppIcon({
    super.key,
    this.size = 68,
    this.radiusFactor = 0.28,
    this.showShadow = true,
  });

  const AuthAppIcon.header({super.key})
      : size = 36,
        radiusFactor = 0.24,
        showShadow = false;

  const AuthAppIcon.splash({super.key})
      : size = 128,
        radiusFactor = 0.24,
        showShadow = true;

  final double size;
  final double radiusFactor;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * radiusFactor);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        // Fixed dark backing so the logo's white glyph stays visible
        // regardless of the active theme (light pages have no dark backdrop).
        color: HalchalColors.of(context).deepSurface,
        borderRadius: radius,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: size * 0.28,
                  offset: Offset(0, size * 0.1),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Image.asset(
          'assets/images/halchal_logo.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
