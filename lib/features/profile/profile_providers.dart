import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/realtime/participation_realtime.dart';

final profileMeProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  watchAppRealtimeTick(ref);
  return ref.read(apiClientProvider).fetchMe();
});

final profileDashboardProvider =
    FutureProvider<CreatorDashboard>((ref) async {
  watchAppRealtimeTick(ref);
  return ref.read(apiClientProvider).fetchDashboard();
});

final profileActiveSubmissionsProvider = FutureProvider<int>((ref) async {
  watchAppRealtimeTick(ref);
  final items =
      await ref.read(apiClientProvider).fetchParticipations(tab: 'active');
  return items.length;
});

final notificationsProvider =
    FutureProvider<List<AppNotification>>((ref) async {
  watchAppRealtimeTick(ref);
  return ref.read(apiClientProvider).fetchNotifications();
});

final unreadNotificationCountProvider = FutureProvider<int>((ref) async {
  watchAppRealtimeTick(ref);
  return ref.read(apiClientProvider).fetchUnreadNotificationCount();
});
