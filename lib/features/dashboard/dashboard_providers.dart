import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/realtime/participation_realtime.dart';

final dashboardProvider = FutureProvider<CreatorDashboard>((ref) async {
  watchAppRealtimeTick(ref);
  return ref.read(apiClientProvider).fetchDashboard();
});
