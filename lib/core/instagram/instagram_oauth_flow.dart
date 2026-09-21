import 'dart:async';
import 'dart:io' show Platform;

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/api_client.dart';
import '../auth/auth_provider.dart';
import '../creator_profile/creator_profile_providers.dart';

/// Shared Instagram OAuth start/callback/complete mechanics — previously
/// duplicated line-for-line between connected_accounts_screen.dart and
/// verification_gate_screen.dart, which meant every iOS OAuth fix (there
/// have been three: ASWebAuthenticationSession + preferEphemeral,
/// applying that fix to the signup screen separately, and refreshing
/// profileMeProvider after completion) had to land twice. Any future fix
/// only needs to land here.
///
/// Mix this into a `ConsumerState<T>` that also mixes in
/// `WidgetsBindingObserver` — call [initInstagramOAuthListener] from
/// `initState`, [disposeInstagramOAuthListener] from `dispose`, and
/// [handleAppLifecycleStateForInstagramOAuth] from
/// `didChangeAppLifecycleState`. Override [onInstagramConnected] and
/// [instagramConnectedMessage] for screen-specific behavior after a
/// successful connect.
mixin InstagramOAuthFlow<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  bool connectingInstagram = false;
  StreamSubscription<Uri>? _instagramLinkSub;

  void initInstagramOAuthListener() {
    // Instagram's OAuth consent screen opens in a browser and redirects
    // back here via this custom scheme once the user approves (or cancels).
    _instagramLinkSub = AppLinks().uriLinkStream.listen(
          handleInstagramCallback,
          onError: (_) {},
        );
  }

  void disposeInstagramOAuthListener() {
    _instagramLinkSub?.cancel();
  }

  /// Safety net: if the user backed out of the Instagram browser without
  /// the deep link ever firing (e.g. just closed it), don't leave the
  /// connect button stuck spinning forever.
  void handleAppLifecycleStateForInstagramOAuth(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (!connectingInstagram) return;
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted && connectingInstagram) {
        setState(() => connectingInstagram = false);
      }
    });
  }

  void handleInstagramCallback(Uri uri) {
    if (uri.scheme != 'halchal' || uri.host != 'instagram-callback') return;
    final activeProfile = ref.read(activeCreatorProfileProvider);
    if (activeProfile == null) return;

    final status = uri.queryParameters['status'];
    final transactionId = uri.queryParameters['transactionId'];
    if (status == 'ready' && transactionId != null) {
      completeInstagramOAuth(transactionId, activeProfile.id);
      return;
    }
    if (!mounted) return;
    setState(() => connectingInstagram = false);
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

  Future<void> startInstagramOAuth(String profileId) async {
    setState(() => connectingInstagram = true);
    try {
      final start = await ref.read(apiClientProvider).startInstagramOAuth(profileId);
      if (Platform.isIOS) {
        // ASWebAuthenticationSession, not externalApplication — Instagram
        // registers www.instagram.com as an iOS Universal Link domain, so
        // handing the authorize URL to "the external app" means iOS opens
        // the native Instagram app itself (when installed) instead of a
        // browser. Instagram's app then fails with a generic error since
        // this isn't a real Meta SDK integration. ASWebAuthenticationSession
        // is Apple's purpose-built OAuth API and is isolated from that
        // automatic Universal Link takeover, while still reliably handing
        // the halchal:// redirect back to us as its return value.
        final result = await FlutterWebAuth2.authenticate(
          url: start.authorizationUrl,
          callbackUrlScheme: 'halchal',
          // preferEphemeral: true — no shared Safari cookies. The backend
          // already sends force_authentication=1 (always show a fresh
          // Instagram login), so a shared session that's stale/mismatched
          // could be fighting that. A fully isolated session removes any
          // cookie state to conflict with — confirmed live: without this,
          // Instagram's own page consistently failed with a generic
          // "Something went wrong" on a real device before ever reaching
          // our callback.
          options: const FlutterWebAuth2Options(preferEphemeral: true),
        );
        handleInstagramCallback(Uri.parse(result));
        return;
      }
      // externalApplication (full Chrome), not inAppBrowserView —
      // SFSafariViewController is unreliable at handing custom-scheme
      // redirects back to the app; full Chrome does this consistently on
      // Android, which doesn't have iOS's Universal Link takeover issue.
      final launched = await launchUrl(
        Uri.parse(start.authorizationUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!launched) throw Exception('launch failed');
      // connectingInstagram stays true (shows a spinner) while the user is
      // in the Instagram browser — handleInstagramCallback or the
      // lifecycle safety net above clears it once they return.
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => connectingInstagram = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => connectingInstagram = false);
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

  Future<void> completeInstagramOAuth(String transactionId, String profileId) async {
    try {
      await ref.read(apiClientProvider).completeInstagramOAuth(profileId, transactionId);
      onInstagramConnected();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(instagramConnectedMessage), behavior: SnackBarBehavior.floating),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => connectingInstagram = false);
    }
  }

  /// Called right after a successful connect, before the snackbar shows —
  /// override to invalidate whichever providers this screen depends on.
  void onInstagramConnected();

  /// Override for screen-specific post-connect messaging (e.g. the signup
  /// gate mentions admin review; the profile screen doesn't need to).
  String get instagramConnectedMessage => 'Instagram connected!';
}
