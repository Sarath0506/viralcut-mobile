import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../creator_profile/creator_profile_providers.dart';
import 'auth_storage.dart';

enum AuthStatus { unknown, authed, unauthed }

final authStorageProvider = Provider<AuthStorage>((ref) => AuthStorage());

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(authStorageProvider);
  final notifier = ref.read(authStateProvider.notifier);
  return ApiClient(
    storage: storage,
    onSessionRefreshed: notifier.onSessionRefreshed,
    onSessionExpired: notifier.onSessionExpired,
  );
});

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthStatus>((ref) {
  return AuthNotifier(ref);
});

class AuthNotifier extends StateNotifier<AuthStatus> {
  AuthNotifier(this._ref) : super(AuthStatus.unknown) {
    _init();
  }

  final Ref _ref;

  Future<void> _init() async {
    // Keychain reads can hang on iOS (observed after switching signing
    // identities between builds) — the splash screen polls this state
    // indefinitely, so an unbounded read here means an infinite spinner.
    // Fall back to unauthed rather than block the app from ever loading.
    String? token;
    try {
      token = await _ref
          .read(authStorageProvider)
          .getAccessToken()
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      token = null;
    }
    state = token != null ? AuthStatus.authed : AuthStatus.unauthed;
  }

  Future<void> onSessionRefreshed(AuthSession session) async {
    // Same hang risk as the reads guarded in _init() above (signing-identity
    // switches between builds can wedge the Keychain platform channel) — a
    // stuck write here previously blocked the whole refresh-and-retry chain
    // until callers' own 45s deadlines fired, surfacing as a misleading
    // "Request timed out" instead of the real auth problem.
    try {
      await _ref
          .read(authStorageProvider)
          .saveTokens(
            accessToken: session.accessToken,
            refreshToken: session.refreshToken,
          )
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Fall through — still reflect the refreshed session in memory so the
      // app can proceed; a later request will re-trigger a refresh if the
      // write genuinely never landed.
    }
    state = AuthStatus.authed;
  }

  Future<void> onSessionExpired() async {
    try {
      await _ref.read(authStorageProvider).clear().timeout(const Duration(seconds: 5));
    } catch (_) {
      // Keychain delete hung/failed — still drop to unauthed so the user
      // sees a login screen instead of a hung request.
    }
    state = AuthStatus.unauthed;
  }

  Future<void> login(AuthSession session) async {
    await onSessionRefreshed(session);
  }

  Future<void> logout() async {
    try {
      await _ref.read(apiClientProvider).logoutSession();
    } catch (_) {
      // Clear local tokens even when API is down.
    }
    await Future.wait([
      _ref.read(authStorageProvider).clear().timeout(const Duration(seconds: 5)).catchError((_) {}),
      _ref.read(activeCreatorProfileIdProvider.notifier).clear(),
    ]);
    state = AuthStatus.unauthed;
  }

  Future<void> deleteAccount() async {
    await _ref.read(apiClientProvider).deleteAccount();
    await Future.wait([
      _ref.read(authStorageProvider).clear(),
      _ref.read(activeCreatorProfileIdProvider.notifier).clear(),
    ]);
    state = AuthStatus.unauthed;
  }
}
