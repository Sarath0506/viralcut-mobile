import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/halchal_colors.dart';

/// A FutureProvider that fails once caches that AsyncError forever — Riverpod
/// never retries it on its own. Every .when(error: ...) branch used to just
/// show the raw message with nothing to tap, so a single transient hiccup
/// (a network blip, a session-refresh race right after the app resumes from
/// background) left the screen permanently stuck until a full app restart
/// recreated the provider from scratch. This gives every one of those
/// branches a real way out: tapping retries invalidates the failed provider
/// and re-reads it right there, no relaunch required.
class RetryErrorView extends StatelessWidget {
  const RetryErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final vc = HalchalColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 36, color: vc.muted),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: vc.muted, height: 1.4),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
