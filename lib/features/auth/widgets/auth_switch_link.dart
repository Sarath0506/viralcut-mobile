import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'auth_ui.dart';

/// Single footer line: "New to ViralCut? **Sign up**" (link only on the action word).
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
    final primary = Theme.of(context).colorScheme.primary;
    return Center(
      child: RichText(
        text: TextSpan(
          style: AuthUi.bodyFont(context).copyWith(
            color: const Color(0xFF64748B),
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
              recognizer: TapGestureRecognizer()..onTap = () => context.go(route),
            ),
          ],
        ),
      ),
    );
  }
}
