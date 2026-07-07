import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/layout/app_spacing.dart';
import '../../../theme/halchal_colors.dart';
import 'auth_ui.dart';

/// Footer account switcher with a full-height tap target.
class AuthSwitchLink extends StatelessWidget {
  const AuthSwitchLink({
    super.key,
    required this.leadText,
    required this.linkText,
    required this.route,
  });

  final String leadText;
  final String linkText;
  final String route;

  @override
  Widget build(BuildContext context) {
    final vc = HalchalColors.of(context);
    final primary = Theme.of(context).colorScheme.primary;

    return Center(
      child: TextButton(
        onPressed: () => context.go(route),
        style: TextButton.styleFrom(
          minimumSize: const Size(0, AppSpacing.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text.rich(
          TextSpan(
            style: AuthUi.bodyFont(context).copyWith(
              color: vc.muted,
              fontSize: 14,
            ),
            children: [
              TextSpan(text: leadText),
              TextSpan(
                text: linkText,
                style: TextStyle(
                  color: primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}