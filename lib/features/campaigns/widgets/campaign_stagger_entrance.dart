import 'package:flutter/material.dart';

/// Dashboard-style fade + slide-up entrance for vertically stacked campaign cards.
class CampaignStaggerEntrance extends StatelessWidget {
  const CampaignStaggerEntrance({
    super.key,
    required this.index,
    required this.animation,
    required this.child,
  });

  final int index;
  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final start = index * 0.1;
    final curved = CurvedAnimation(
      parent: animation,
      curve: Interval(
        start.clamp(0.0, 0.85),
        (start + 0.5).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );

    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        return Opacity(
          opacity: curved.value,
          child: Transform.translate(
            offset: Offset(0, (1 - curved.value) * 18),
            child: Transform.scale(
              scale: 0.97 + (curved.value * 0.03),
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }
}
