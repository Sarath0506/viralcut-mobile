import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/creator_profile/creator_profile_providers.dart';
import '../../core/widgets/vc_scaffold.dart';
import '../../theme/halchal_colors.dart';
import '../profile/profile_providers.dart';

/// Shown once a new signup has connected Instagram — the only thing left
/// is a human admin approving the account, so there's nothing left for the
/// clipper to do here but wait. Bounces back to the form
/// (verification_gate_screen.dart) if Instagram gets rejected, or on to
/// /dashboard automatically once an admin approves it (both handled by
/// app_router.dart's redirect, driven by profileMeProvider).
///
/// Also double-checks on its own build that Instagram is actually
/// connected (via creatorProfilesProvider) and bounces back to the form if
/// not — landing here should only happen once verification_gate_screen.dart
/// confirms a real connection, but that confirmation reads client-side
/// provider state that can go stale across an account switch on the same
/// running app (see auth_router_refresh.dart, which invalidates that state
/// on login — the actual fix; this is a defensive backstop, not a
/// replacement for it).
class VerificationWaitingScreen extends ConsumerWidget {
  const VerificationWaitingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(profileMeProvider);
    final profiles = ref.watch(creatorProfilesProvider);
    final activeProfile = ref.watch(activeCreatorProfileProvider);
    final vc = HalchalColors.of(context);

    final instagramHandleConnected =
        (activeProfile?.socialLinks['instagram'] as String?)?.isNotEmpty == true;

    ref.listen(profileMeProvider, (previous, next) {
      final status = next.valueOrNull?['onboarding']
          ?['instagramReviewStatus'] as String?;
      if (status == 'rejected') context.go('/verification');
    });

    // ref.listen above only fires on a live transition while this screen is
    // already open. Someone reopening the app after already being rejected
    // (no live transition to catch) would otherwise be stuck seeing "Under
    // review" forever, with no path back to reconnect — check the current
    // value too, not just future changes.
    final currentInstagramStatus =
        me.valueOrNull?['onboarding']?['instagramReviewStatus'] as String?;
    if (currentInstagramStatus == 'rejected') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/verification');
      });
    }

    if (profiles.hasValue && !instagramHandleConnected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/verification');
      });
    }

    return VcScaffold(
      title: 'Verify your account',
      actions: [
        IconButton(
          icon: const Icon(Icons.logout_rounded),
          tooltip: 'Log out',
          onPressed: () => ref.read(authStateProvider.notifier).logout(),
        ),
      ],
      body: me.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (_) {
          return Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: vc.warning.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.hourglass_top_rounded, color: vc.warning, size: 32),
                ),
                const SizedBox(height: 24),
                Text(
                  'Under review',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: vc.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'We\'re manually reviewing your Instagram account to confirm you\'re a real clipper — this usually takes under a day.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: vc.muted),
                ),
                if (activeProfile != null && instagramHandleConnected) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: vc.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: vc.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.camera_alt_outlined, size: 16, color: vc.muted),
                        const SizedBox(width: 8),
                        Text(
                          '@${activeProfile.handle}',
                          style: GoogleFonts.inter(
                              fontSize: 13, fontWeight: FontWeight.w600, color: vc.onSurface),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  'You\'ll be let in automatically the moment it\'s approved — no need to keep checking.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 11, color: vc.muted),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
