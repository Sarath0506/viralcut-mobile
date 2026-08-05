import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_provider.dart';

class UpdateAvailable {
  const UpdateAvailable({required this.latestVersion, this.storeUrl});

  final String latestVersion;
  final String? storeUrl;
}

/// Remembers the last update version the user dismissed, so the banner
/// doesn't reappear for the same release once closed.
final dismissedUpdateVersionProvider =
    StateNotifierProvider<DismissedUpdateVersionNotifier, String?>((ref) {
  return DismissedUpdateVersionNotifier();
});

class DismissedUpdateVersionNotifier extends StateNotifier<String?> {
  DismissedUpdateVersionNotifier() : super(null) {
    _load();
  }

  static const _key = 'dismissed_update_version';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_key);
  }

  Future<void> dismiss(String version) async {
    state = version;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, version);
  }
}

/// Compares two dot-separated version strings, e.g. "1.10.0" vs "1.9.2".
/// Returns > 0 if [a] is newer than [b].
int compareVersions(String a, String b) {
  final partsA = a.split('.').map((p) => int.tryParse(p) ?? 0).toList();
  final partsB = b.split('.').map((p) => int.tryParse(p) ?? 0).toList();
  final len = partsA.length > partsB.length ? partsA.length : partsB.length;
  for (var i = 0; i < len; i++) {
    final va = i < partsA.length ? partsA[i] : 0;
    final vb = i < partsB.length ? partsB[i] : 0;
    if (va != vb) return va - vb;
  }
  return 0;
}

/// Resolves to a non-null [UpdateAvailable] when a newer version is
/// published for the current platform and the user hasn't dismissed it yet.
final updateAvailableProvider = FutureProvider<UpdateAvailable?>((ref) async {
  final dismissed = ref.watch(dismissedUpdateVersionProvider);

  final versionInfo = await ref.read(apiClientProvider).fetchAppVersion();
  final platformInfo = Platform.isIOS ? versionInfo.ios : versionInfo.android;
  final latest = platformInfo.latestVersion;
  if (latest == null || latest.isEmpty) return null;
  if (latest == dismissed) return null;

  final packageInfo = await PackageInfo.fromPlatform();
  final current = packageInfo.version;

  if (compareVersions(latest, current) <= 0) return null;

  return UpdateAvailable(latestVersion: latest, storeUrl: platformInfo.storeUrl);
});
