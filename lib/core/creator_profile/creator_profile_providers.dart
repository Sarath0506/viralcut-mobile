import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_provider.dart';
import 'creator_profile.dart';

const _activeProfileIdKey = 'active_creator_profile_id';

final creatorProfilesProvider = FutureProvider<List<CreatorProfile>>((ref) async {
  return ref.read(apiClientProvider).fetchCreatorProfiles();
});

class ActiveCreatorProfileIdNotifier extends StateNotifier<String?> {
  ActiveCreatorProfileIdNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_activeProfileIdKey);
  }

  Future<void> setActive(String profileId) async {
    state = profileId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeProfileIdKey, profileId);
  }

  Future<void> clear() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeProfileIdKey);
  }
}

final activeCreatorProfileIdProvider =
    StateNotifierProvider<ActiveCreatorProfileIdNotifier, String?>(
  (ref) => ActiveCreatorProfileIdNotifier(),
);

/// Resolves the creator's currently active profile: the explicitly selected
/// one if it still exists, otherwise their default profile, otherwise the
/// first profile in the list. Null only while profiles are still loading or
/// if the creator has none yet.
final activeCreatorProfileProvider = Provider<CreatorProfile?>((ref) {
  final profiles = ref.watch(creatorProfilesProvider).valueOrNull;
  if (profiles == null || profiles.isEmpty) return null;

  final activeId = ref.watch(activeCreatorProfileIdProvider);
  if (activeId != null) {
    final match = profiles.where((p) => p.id == activeId);
    if (match.isNotEmpty) return match.first;
  }

  final defaultProfile = profiles.where((p) => p.isDefault);
  return defaultProfile.isNotEmpty ? defaultProfile.first : profiles.first;
});
