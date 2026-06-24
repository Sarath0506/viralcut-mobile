import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/realtime/participation_realtime.dart';

final participationsProvider =
    FutureProvider.family<List<ParticipationListItem>, String>((ref, tab) async {
  watchAppRealtimeTick(ref);
  return ref.read(apiClientProvider).fetchParticipations(tab: tab);
});

final participationDetailProvider =
    FutureProvider.family<Participation, String>((ref, id) async {
  watchAppRealtimeTick(ref);
  return ref.read(apiClientProvider).fetchParticipation(id);
});
