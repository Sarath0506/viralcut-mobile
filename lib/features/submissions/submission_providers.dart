import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/creator_profile/creator_profile_providers.dart';
import '../../core/realtime/participation_realtime.dart';

final participationsProvider =
    FutureProvider.family<List<ParticipationListItem>, String>((ref, tab) async {
  watchAppRealtimeTick(ref);
  final activeProfile = ref.watch(activeCreatorProfileProvider);
  return ref.read(apiClientProvider).fetchParticipations(
        tab: tab,
        creatorProfileId: activeProfile?.id,
      );
});

final participationDetailProvider =
    FutureProvider.family<Participation, String>((ref, id) async {
  watchAppRealtimeTick(ref);
  return ref.read(apiClientProvider).fetchParticipation(id);
});
