import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/creator_profile/creator_profile_providers.dart';
import '../../core/instagram/instagram_oauth_flow.dart';
import '../../core/widgets/retry_error_view.dart';
import '../../core/widgets/social_logo_painters.dart';
import '../../core/widgets/vc_scaffold.dart';
import '../../theme/halchal_colors.dart';
import '../profile/profile_providers.dart';

/// Blocks the rest of the app for new signups until Instagram is manually
/// reviewed by an admin, to confirm this is a real clipper and not an
/// outsider. Existing users are grandfathered in via
/// `requiresOnboardingGate: false` and never see this screen — see
/// app_router.dart's redirect.
///
/// PAN + Aadhaar auto-verification (via Cashfree) is fully built on the
/// backend (submitPan/submitAadhaar) but deliberately not surfaced here
/// right now — the Cashfree account's balance is blocking real submissions,
/// so requiring it would block every signup. Re-add those two sections
/// once that's sorted (see users.service.ts's onboardingGateCleared).
class VerificationGateScreen extends ConsumerStatefulWidget {
  const VerificationGateScreen({super.key});

  @override
  ConsumerState<VerificationGateScreen> createState() =>
      _VerificationGateScreenState();
}

class _VerificationGateScreenState extends ConsumerState<VerificationGateScreen>
    with WidgetsBindingObserver, InstagramOAuthFlow<VerificationGateScreen> {
  bool _navigatedToWaiting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initInstagramOAuthListener();
  }

  @override
  void dispose() {
    disposeInstagramOAuthListener();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      handleAppLifecycleStateForInstagramOAuth(state);

  @override
  void onInstagramConnected() {
    ref.invalidate(creatorProfilesProvider);
    // The reconnect path (rejected -> pending) changes instagramReviewStatus,
    // which lives on profileMeProvider, not creatorProfilesProvider — without
    // this, awaitingReview below keeps evaluating against the stale
    // pre-reconnect status and the screen never advances to the waiting page.
    ref.invalidate(profileMeProvider);
  }

  @override
  String get instagramConnectedMessage => 'Instagram connected! Waiting on admin review.';

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(profileMeProvider);
    final profiles = ref.watch(creatorProfilesProvider);
    final activeProfile = ref.watch(activeCreatorProfileProvider);
    final vc = HalchalColors.of(context);

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
        error: (e, _) => RetryErrorView(
          message: '$e',
          onRetry: () => ref.invalidate(profileMeProvider),
        ),
        data: (user) {
          final onboarding = (user['onboarding'] as Map<String, dynamic>?) ?? {};
          final instagramReviewStatus =
              onboarding['instagramReviewStatus'] as String? ?? 'not_started';
          final instagramRejectionReason = onboarding['instagramRejectionReason'] as String?;
          final instagramHandleConnected =
              (activeProfile?.socialLinks['instagram'] as String?)?.isNotEmpty == true;
          final instagramLoading = profiles.isLoading && activeProfile == null;

          final awaitingReview = instagramHandleConnected &&
              (instagramReviewStatus == 'not_started' || instagramReviewStatus == 'pending');

          if (awaitingReview && !_navigatedToWaiting) {
            _navigatedToWaiting = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) context.go('/verification/waiting');
            });
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            children: [
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: vc.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.verified_user_rounded, color: vc.primary, size: 26),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Almost there',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: vc.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We verify every new clipper before they can browse or join campaigns — connect your Instagram so we can confirm it\'s really you.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: vc.muted),
              ),
              const SizedBox(height: 28),

              _VerificationSection(
                status: instagramReviewStatus,
                failureReason: instagramRejectionReason,
                verifiedNote: 'Reviewed by our team',
                // A rejected status keeps instagramHandleConnected true
                // (the old — now-rejected — connection is still linked), so
                // this must not override the "Rejected" badge in that case.
                pendingOverrideLabel: (instagramHandleConnected && instagramReviewStatus != 'rejected')
                    ? 'Connected — awaiting review'
                    : null,
                // Rejected always gets the button back, regardless of
                // instagramHandleConnected — reconnecting (same or a
                // different account) is exactly how a rejected clipper is
                // meant to retry; the backend resets the review status back
                // to pending once a new connection completes.
                child: (instagramReviewStatus == 'rejected') ||
                        (instagramReviewStatus == 'not_started' && !instagramHandleConnected)
                    ? Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: FilledButton(
                              onPressed: (connectingInstagram || instagramLoading || activeProfile == null)
                                  ? null
                                  : () => startInstagramOAuth(activeProfile.id),
                              style: FilledButton.styleFrom(
                                backgroundColor: vc.primary,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: connectingInstagram || instagramLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : Text(
                                      instagramReviewStatus == 'rejected'
                                          ? 'Reconnect Instagram'
                                          : 'Connect with Instagram',
                                      style: GoogleFonts.inter(
                                          fontSize: 14, fontWeight: FontWeight.w700),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Takes under a minute · your account stays private',
                            style: GoogleFonts.inter(fontSize: 10.5, color: vc.muted),
                          ),
                        ],
                      )
                    : null,
              ),
              const SizedBox(height: 20),
              Text(
                'This screen updates automatically once you\'re verified.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 11, color: vc.muted),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _VerificationSection extends StatelessWidget {
  const _VerificationSection({
    required this.status,
    required this.verifiedNote,
    this.failureReason,
    this.pendingOverrideLabel,
    this.child,
  });

  final String status;
  final String verifiedNote;
  final String? failureReason;
  final String? pendingOverrideLabel;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final vc = HalchalColors.of(context);
    final color = switch (status) {
      'verified' => vc.money,
      'rejected' => vc.error,
      'pending' => vc.warning,
      _ => pendingOverrideLabel != null ? vc.warning : vc.muted,
    };
    final label = pendingOverrideLabel ??
        switch (status) {
          'verified' => 'Verified',
          'rejected' => 'Rejected',
          'pending' => 'Under review',
          _ => 'Not started',
        };
    final borderColor = status == 'verified' || pendingOverrideLabel != null
        ? color.withValues(alpha: 0.35)
        : vc.border;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SocialLogoBox(platform: 'instagram', size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Instagram',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14, fontWeight: FontWeight.w700, color: vc.onSurface),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                      fontSize: 10, fontWeight: FontWeight.w700, color: color),
                ),
              ),
            ],
          ),
          if (status == 'verified') ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 54),
              child: Text(verifiedNote,
                  style: GoogleFonts.inter(fontSize: 11, color: vc.muted)),
            ),
          ],
          if (status == 'rejected' && failureReason?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 54),
              child: Text(failureReason!,
                  style: GoogleFonts.inter(fontSize: 11, color: vc.error, height: 1.4)),
            ),
          ],
          if (child != null) ...[
            const SizedBox(height: 14),
            child!,
          ],
        ],
      ),
    );
  }
}
