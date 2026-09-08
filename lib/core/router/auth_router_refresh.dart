import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/profile/profile_providers.dart';
import '../auth/auth_provider.dart';
import '../creator_profile/creator_profile_providers.dart';

/// Re-evaluates GoRouter redirects when [authStateProvider] or
/// [profileMeProvider] changes. The latter drives the new-signup
/// verification gate (see verification_gate_screen.dart) — without
/// listening to it, the router would only re-check the gate on the next
/// user-initiated navigation, letting a still-unverified signup sit on
/// whatever route it landed on right after login until they tap something.
/// See dart-flutter-patterns: GoRouter + refreshListenable.
class AuthRouterRefresh extends ChangeNotifier {
  AuthRouterRefresh();

  void onAuthStateChanged() => notifyListeners();
}

final authRouterRefreshProvider = Provider<AuthRouterRefresh>((ref) {
  final refresh = AuthRouterRefresh();
  ref.listen<AuthStatus>(authStateProvider, (previous, next) {
    refresh.onAuthStateChanged();
    // A different account can sign into this same running app instance
    // (logout then log in as someone else, or — during testing — a fresh
    // signup that reuses a phone number after the old account was
    // deleted). profileMeProvider/creatorProfilesProvider cache their
    // last-fetched value with no per-user key, so without invalidating
    // here a brand-new session can be served the previous account's
    // stale data. Confirmed live: this made the verification gate think
    // Instagram was already connected for a signup that had never
    // touched it. Riverpod only calls this listener when the value
    // actually changes, so a same-session token refresh (already authed
    // -> still authed) never re-triggers it — this only fires on a
    // genuine new sign-in.
    if (next == AuthStatus.authed) {
      ref.invalidate(profileMeProvider);
      ref.invalidate(creatorProfilesProvider);
    }
  });
  ref.listen(profileMeProvider, (_, __) {
    refresh.onAuthStateChanged();
  });
  ref.onDispose(refresh.dispose);
  return refresh;
});
