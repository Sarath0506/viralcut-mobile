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
    final token = await _ref.read(authStorageProvider).getAccessToken();
    state = token != null ? AuthStatus.authed : AuthStatus.unauthed;
  }

  Future<void> onSessionRefreshed(AuthSession session) async {
    await _ref.read(authStorageProvider).saveTokens(
          accessToken: session.accessToken,
          refreshToken: session.refreshToken,
        );
    state = AuthStatus.authed;
  }

  Future<void> onSessionExpired() async {
    await _ref.read(authStorageProvider).clear();
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
      _ref.read(authStorageProvider).clear(),
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
