import 'package:flutter/material.dart';
import '../../theme/viralcut_colors.dart';
import '../../theme/viralcut_text_styles.dart';
import 'app_spacing.dart';

class OnboardingTextBlock extends StatelessWidget {
  const OnboardingTextBlock({
    super.key,
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final vc = ViralCutColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: ViralCutTextStyles.screenTitle(context).copyWith(
              fontSize: 27,
              color: vc.onSurface,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: ViralCutTextStyles.bodyText(context).copyWith(
                color: vc.muted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
