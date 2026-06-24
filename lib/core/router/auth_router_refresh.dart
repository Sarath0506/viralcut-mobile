import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_provider.dart';

/// Re-evaluates GoRouter redirects when [authStateProvider] changes.
/// See dart-flutter-patterns: GoRouter + refreshListenable.
class AuthRouterRefresh extends ChangeNotifier {
  AuthRouterRefresh();

  void onAuthStateChanged() => notifyListeners();
}

final authRouterRefreshProvider = Provider<AuthRouterRefresh>((ref) {
  final refresh = AuthRouterRefresh();
  ref.listen<AuthStatus>(authStateProvider, (_, __) {
    refresh.onAuthStateChanged();
  });
  ref.onDispose(refresh.dispose);
  return refresh;
});
