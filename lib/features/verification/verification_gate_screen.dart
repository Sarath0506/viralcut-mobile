import 'dart:async';
import 'dart:io' show Platform;

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/creator_profile/creator_profile_providers.dart';
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
    with WidgetsBindingObserver {
  bool _connectingInstagram = false;
  StreamSubscription<Uri>? _linkSub;
  bool _navigatedToWaiting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _linkSub = AppLinks().uriLinkStream.listen(
          _handleInstagramCallback,
          onError: (_) {},
        );
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (!_connectingInstagram) return;
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted && _connectingInstagram) {
        setState(() => _connectingInstagram = false);
      }
    });
  }

  void _handleInstagramCallback(Uri uri) {
    // ignore: avoid_print
    print('[DEBUG][verification] _handleInstagramCallback: $uri');
    if (uri.scheme != 'halchal' || uri.host != 'instagram-callback') return;
    final activeProfile = ref.read(activeCreatorProfileProvider);
    if (activeProfile == null) return;

    final status = uri.queryParameters['status'];
    final transactionId = uri.queryParameters['transactionId'];
    if (status == 'ready' && transactionId != null) {
      _completeInstagramOAuth(transactionId, activeProfile.id);
      return;
    }
    if (!mounted) return;
    setState(() => _connectingInstagram = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          uri.queryParameters['error'] == 'OAUTH_CANCELLED'
              ? 'Instagram connection cancelled.'
              : 'Instagram connection failed. Please try again.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _startInstagramOAuth() async {
    final activeProfile = ref.read(activeCreatorProfileProvider);
    if (activeProfile == null) return;
    setState(() => _connectingInstagram = true);
    try {
      final start =
          await ref.read(apiClientProvider).startInstagramOAuth(activeProfile.id);
      // ignore: avoid_print
      print('[DEBUG][verification] startInstagramOAuth ok: transactionId=${start.transactionId}, url=${start.authorizationUrl}');
      if (Platform.isIOS) {
        // ASWebAuthenticationSession, not externalApplication — see
        // connected_accounts_screen.dart for the full explanation (Universal
        // Link takeover into the native Instagram app on iOS otherwise).
        // preferEphemeral: true avoids a stale/shared Safari session
        // fighting the backend's force_authentication=1.
        final result = await FlutterWebAuth2.authenticate(
          url: start.authorizationUrl,
          callbackUrlScheme: 'halchal',
          options: const FlutterWebAuth2Options(preferEphemeral: true),
        );
        // ignore: avoid_print
        print('[DEBUG][verification] FlutterWebAuth2.authenticate returned: $result');
        _handleInstagramCallback(Uri.parse(result));
        return;
      }
      final launched = await launchUrl(
        Uri.parse(start.authorizationUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!launched) throw Exception('launch failed');
    } on ApiException catch (e) {
      // ignore: avoid_print
      print('[DEBUG][verification] startInstagramOAuth ApiException: code=${e.code}, message=${e.message}');
      if (!mounted) return;
      setState(() => _connectingInstagram = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      // ignore: avoid_print
      print('[DEBUG][verification] _startInstagramOAuth caught: ${e.runtimeType}: $e');
      if (!mounted) return;
      setState(() => _connectingInstagram = false);
      final cancelled = e is PlatformException && e.code == 'CANCELED';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            cancelled
                ? 'Instagram connection cancelled.'
                : 'Could not open Instagram. Please try again.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _completeInstagramOAuth(String transactionId, String profileId) async {
    try {
      await ref.read(apiClientProvider).completeInstagramOAuth(profileId, transactionId);
      ref.invalidate(creatorProfilesProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Instagram connected! Waiting on admin review.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _connectingInstagram = false);
    }
  }

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
        error: (e, _) => Center(child: Text('$e')),
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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            children: [
              Text(
                'Almost there',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: vc.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'We verify every new clipper before they can browse or join campaigns — connect your Instagram so we can confirm it\'s really you.',
                style: GoogleFonts.inter(fontSize: 13, height: 1.45, color: vc.muted),
              ),
              const SizedBox(height: 24),

              _VerificationSection(
                icon: Icons.camera_alt_outlined,
                title: 'Instagram',
                status: instagramReviewStatus,
                failureReason: instagramRejectionReason,
                verifiedNote: 'Reviewed by our team',
                pendingOverrideLabel: instagramHandleConnected ? 'Connected — awaiting review' : null,
                child: (instagramReviewStatus == 'not_started' || instagramReviewStatus == 'rejected') &&
                        !instagramHandleConnected
                    ? SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: (_connectingInstagram || instagramLoading || activeProfile == null)
                              ? null
                              : _startInstagramOAuth,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF7C3AED),
                            minimumSize: const Size.fromHeight(44),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: _connectingInstagram || instagramLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Connect with Instagram'),
                        ),
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
    required this.icon,
    required this.title,
    required this.status,
    required this.verifiedNote,
    this.failureReason,
    this.pendingOverrideLabel,
    this.child,
  });

  final IconData icon;
  final String title;
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: vc.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: vc.onSurface),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
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
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 30),
              child: Text(verifiedNote,
                  style: GoogleFonts.inter(fontSize: 11, color: vc.muted)),
            ),
          ],
          if (status == 'rejected' && failureReason?.isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 30),
              child: Text(failureReason!,
                  style: GoogleFonts.inter(fontSize: 11, color: vc.error, height: 1.4)),
            ),
          ],
          if (child != null) ...[
            const SizedBox(height: 12),
            child!,
          ],
        ],
      ),
    );
  }
}
