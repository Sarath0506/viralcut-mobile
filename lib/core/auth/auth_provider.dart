import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import 'auth_storage.dart';

final authStorageProvider = Provider<AuthStorage>((ref) => AuthStorage());

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(storage: ref.watch(authStorageProvider));
});

final authStateProvider = StateNotifierProvider<AuthNotifier, bool>((ref) {
  return AuthNotifier(ref);
});

class AuthNotifier extends StateNotifier<bool> {
  AuthNotifier(this._ref) : super(false) {
    _init();
  }

  final Ref _ref;

  Future<void> _init() async {
    final token = await _ref.read(authStorageProvider).getAccessToken();
    state = token != null;
  }

  Future<void> login(AuthSession session) async {
    await _ref.read(authStorageProvider).saveTokens(
          accessToken: session.accessToken,
          refreshToken: session.refreshToken,
        );
    state = true;
  }

  Future<void> logout() async {
    try {
      await _ref.read(apiClientProvider).logoutSession();
    } catch (_) {
      // Clear local tokens even when API is down.
    }
    await _ref.read(authStorageProvider).clear();
    state = false;
  }
}
