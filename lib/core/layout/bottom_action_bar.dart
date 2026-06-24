import 'package:flutter/material.dart';

import 'app_spacing.dart';

/// Pinned bottom zone for primary CTA, page dots, and secondary links.
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({
    super.key,
    this.indicator,
    required this.primary,
    this.secondary,
  });

  final Widget? indicator;
  final Widget primary;
  final Widget? secondary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.bottomActionPadding(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (indicator != null) ...[
            indicator!,
            const SizedBox(height: AppSpacing.md),
          ],
          primary,
          if (secondary != null) ...[
            const SizedBox(height: AppSpacing.sm),
            secondary!,
          ],
        ],
      ),
    );
  }
}
