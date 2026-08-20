import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../api/api_client.dart';
import '../auth/auth_provider.dart';
import '../realtime/realtime_invalidation.dart';

/// The message that launched the app from a terminated state, captured in
/// main() right after Firebase.initializeApp() (per Firebase's guidance —
/// reading getInitialMessage() late can miss it on some platforms). Consumed
/// once by [PushNotificationService.init] after auth/router are ready.
RemoteMessage? pendingLaunchMessage;

/// Requests push permission, registers the FCM device token with the
/// backend, and wires foreground/background/terminated message handling.
///
/// Call [init] once after a successful login (mirrors how RealtimeSync
/// connects the realtime socket) — not from main() before auth, since
/// registering a token has nowhere to attach to without a signed-in user.
/// Safe to call again on every login (e.g. after logout/re-login as a
/// different creator on the same device) — permission and listeners are
/// only wired once, but the token is re-registered against whichever user
/// is currently authenticated each time.
class PushNotificationService {
  PushNotificationService(this._router);

  // Not read yet — _handleNotificationTap is stubbed until the backend
  // defines the push payload shape (see its TODO below). Kept here so the
  // eventual `_router.go`/`_router.push` call has no plumbing left to add.
  // ignore: unused_field
  final GoRouter _router;

  bool _listenersAttached = false;
  ApiClient? _apiClient;

  Future<void> init(WidgetRef ref) async {
    _apiClient = ref.read(apiClientProvider);
    final messaging = FirebaseMessaging.instance;

    if (!_listenersAttached) {
      _listenersAttached = true;

      final settings = await messaging.requestPermission(alert: true, badge: true, sound: true);
      // authorizationStatus is the actual answer — denied/notDetermined here
      // means the OS will silently drop every notification we send, even
      // though FCM itself reports the send as successful. There's no way to
      // re-prompt on Android/iOS after a denial; the user has to grant it
      // manually in system Settings.
      debugPrint('[Push] permission status: ${settings.authorizationStatus}');

      messaging.onTokenRefresh.listen((newToken) {
        final client = _apiClient;
        if (client != null) unawaited(_registerToken(client, newToken));
      });

      FirebaseMessaging.onMessage.listen((message) {
        debugPrint('[Push] foreground message: ${message.data}');
        // No system banner shows for foreground messages by default — just
        // refresh the existing notification bell/badge instead of building
        // a separate custom banner.
        invalidateAppDataCaches(ref);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        _handleNotificationTap(message.data);
      });

      final launchMessage = pendingLaunchMessage;
      if (launchMessage != null) {
        pendingLaunchMessage = null;
        _handleNotificationTap(launchMessage.data);
      }
    }

    final token = await messaging.getToken();
    final client = _apiClient;
    if (token != null && client != null) {
      await _registerToken(client, token);
    }
  }

  Future<void> _registerToken(ApiClient apiClient, String token) async {
    try {
      await apiClient.registerDeviceToken(
        token: token,
        platform: Platform.isIOS ? 'ios' : 'android',
      );
    } catch (e) {
      debugPrint('[Push] failed to register device token: $e');
    }
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    // TODO(push-routing): backend hasn't defined the push data payload shape
    // yet. Once it sends a route/type field, map it to a screen here — reuse
    // notifications_screen.dart's _shellTabRoutes pattern (context.go for
    // ShellRoute tabs like /dashboard, /wallet, etc., router.push otherwise)
    // to avoid the GlobalKey crash that pattern was built to prevent.
    debugPrint('[Push] notification tapped, payload: $data');
  }
}
