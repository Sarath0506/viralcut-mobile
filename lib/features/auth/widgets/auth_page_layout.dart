import 'package:flutter/material.dart';

import '../../../theme/token_colors.dart';
import 'auth_app_icon.dart';
import 'auth_switch_link.dart';
import 'auth_ui.dart';

/// Stitch auth layout: centered icon → title → white form card → footer link.
class AuthPageLayout extends StatelessWidget {
  const AuthPageLayout({
    super.key,
    required this.title,
    required this.form,
    this.subtitle,
    this.footer,
    this.showBack = false,
    this.onBack,
  });

  final String title;
  final String? subtitle;
  final Widget form;
  final AuthSwitchLink? footer;
  final bool showBack;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return AuthGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showBack)
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    color: ViralCutTokenColors.onSurfaceLight,
                    onPressed: onBack,
                  ),
                )
              else
                const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    children: [
                      const AuthAppIcon(),
                      const SizedBox(height: 20),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: AuthUi.displayFont(context).copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: ViralCutTokenColors.onSurfaceLight,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          subtitle!,
                          textAlign: TextAlign.center,
                          style: AuthUi.bodyFont(context).copyWith(
                            color: ViralCutTokenColors.mutedLight,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      form,
                    ],
                  ),
                ),
              ),
              if (footer != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: footer!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
