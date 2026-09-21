import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../api/api_client.dart';
import '../auth/auth_provider.dart';
import '../realtime/realtime_invalidation.dart';

// Same channel id the Android manifest declares for system-triggered
// (background/killed) FCM notifications — reusing it here means a
// foreground-shown local notification looks and behaves identically to one
// Android shows on its own, instead of falling into an ad-hoc default
// channel a user could have muted separately.
const _androidChannel = AndroidNotificationChannel(
  'halchal_default_channel',
  'Halchal notifications',
  importance: Importance.high,
);

final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

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

      await _initLocalNotifications();

      messaging.onTokenRefresh.listen((newToken) {
        final client = _apiClient;
        if (client != null) unawaited(_registerToken(client, newToken));
      });

      FirebaseMessaging.onMessage.listen((message) {
        debugPrint('[Push] foreground message: ${message.data}');
        // iOS/Android both suppress the system banner for a message
        // received while the app is frontmost — showing one ourselves via a
        // local notification is the only way a creator sees it without
        // having the app open at exactly notification-bell-checking time.
        unawaited(_showForegroundNotification(message));
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

  Future<void> _initLocalNotifications() async {
    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Permission is requested once above via
        // messaging.requestPermission — asking again here via Darwin's own
        // init would show a second, redundant system prompt.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null) return;
        _handleNotificationTap(jsonDecode(payload) as Map<String, dynamic>);
      },
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    await _localNotifications.show(
      id: message.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
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
