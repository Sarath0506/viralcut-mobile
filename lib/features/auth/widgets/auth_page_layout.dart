import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/layout/app_spacing.dart';
import '../../../theme/halchal_colors.dart';
import 'auth_app_icon.dart';
import 'auth_switch_link.dart';
import 'auth_ui.dart';

/// Auth layout: back arrow + header text, large left-aligned title, flat form.
class AuthPageLayout extends StatelessWidget {
  const AuthPageLayout({
    super.key,
    required this.title,
    required this.form,
    this.headerTitle,
    this.titleHighlight,
    this.subtitle,
    this.footer,
    this.showBack = false,
    this.onBack,
  });

  final String title;
  final String? headerTitle;
  final String? titleHighlight;
  final String? subtitle;
  final Widget form;
  final AuthSwitchLink? footer;
  final bool showBack;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final vc = HalchalColors.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final bottomSafe = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: vc.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
              child: Row(
                children: [
                  if (showBack)
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      color: vc.onSurface,
                      onPressed: onBack,
                    )
                  else
                    const SizedBox(width: AppSpacing.screenHorizontal),
                  Expanded(
                    child: Center(
                      child: Text(
                        headerTitle ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: vc.muted,
                        ),
                      ),
                    ),
                  ),
                  if (showBack)
                    const SizedBox(width: 48)
                  else
                    const SizedBox.shrink(),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: viewInsets.bottom + AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenHorizontal,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AuthAppIcon(),
                          const SizedBox(height: AppSpacing.md),
                          _TitleText(
                            title: title,
                            highlight: titleHighlight,
                            highlightColor: primary,
                            onSurface: vc.onSurface,
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              subtitle!,
                              style: AuthUi.bodyFont(context).copyWith(
                                color: vc.muted,
                                fontSize: 15,
                                height: 1.4,
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.lg),
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
    );
  }
}

class _TitleText extends StatelessWidget {
  const _TitleText({
    required this.title,
    required this.onSurface,
    required this.highlightColor,
    this.highlight,
  });

  final String title;
  final String? highlight;
  final Color highlightColor;
  final Color onSurface;

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.plusJakartaSans(
      fontSize: 34,
      fontWeight: FontWeight.w800,
      color: onSurface,
      height: 1.12,
    );

    if (highlight == null || !title.contains(highlight!)) {
      return Text(title, style: base);
    }

    final parts = title.split(highlight!);
    final spans = <TextSpan>[];
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) {
        spans.add(TextSpan(text: parts[i]));
      }
      if (i < parts.length - 1) {
        spans.add(TextSpan(
          text: highlight,
          style: TextStyle(color: highlightColor),
        ));
      }
    }

    return RichText(
      text: TextSpan(style: base, children: spans),
    );
  }
}
