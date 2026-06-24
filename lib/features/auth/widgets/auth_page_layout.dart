import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/layout/app_spacing.dart';
import '../../../theme/viralcut_colors.dart';
import 'auth_app_icon.dart';
import 'auth_switch_link.dart';
import 'auth_ui.dart';

/// Auth layout: back, hero, title, form card, and pinned footer link.
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
    final vc = ViralCutColors.of(context);
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final bottomSafe = MediaQuery.paddingOf(context).bottom;

    return AuthGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: viewInsets.bottom + AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (showBack)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back),
                            color: vc.onSurface,
                            onPressed: onBack,
                            style: IconButton.styleFrom(
                              minimumSize: const Size(
                                AppSpacing.minTouchTarget,
                                AppSpacing.minTouchTarget,
                              ),
                            ),
                          ),
                        )
                      else
                        const SizedBox(height: AppSpacing.sm),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenHorizontal,
                        ),
                        child: Column(
                          children: [
                            const AuthAppIcon(),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: AuthUi.displayFont(context).copyWith(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0,
                                color: vc.onSurface,
                                height: 1.2,
                              ),
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                subtitle!,
                                textAlign: TextAlign.center,
                                style: AuthUi.bodyFont(context).copyWith(
                                  color: vc.muted,
                                  fontSize: 15,
                                  height: 1.4,
                                ),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.md),
                            form,
                          ],
                        ).animate().fade(duration: 420.ms, curve: Curves.easeOut).slideY(
                              begin: 0.06,
                              duration: 420.ms,
                              curve: Curves.easeOut,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              if (footer != null)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.screenHorizontal,
                    AppSpacing.sm,
                    AppSpacing.screenHorizontal,
                    bottomSafe > 0 ? bottomSafe : AppSpacing.screenBottom,
                  ),
                  child: footer!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}