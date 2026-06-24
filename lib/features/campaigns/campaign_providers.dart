import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/realtime/participation_realtime.dart';

final campaignsProvider = FutureProvider<List<Campaign>>((ref) async {
  watchAppRealtimeTick(ref);
  return ref.read(apiClientProvider).fetchCampaigns();
});

final campaignDetailProvider =
    FutureProvider.family<Campaign, String>((ref, id) async {
  watchAppRealtimeTick(ref);
  return ref.read(apiClientProvider).fetchCampaign(id);
});

final campaignParticipationProvider =
    FutureProvider.family<Participation?, String>((ref, campaignId) async {
  watchAppRealtimeTick(ref);
  try {
    return await ref
        .read(apiClientProvider)
        .fetchParticipationByCampaign(campaignId);
  } on ApiException catch (e) {
    if (e.code == 'NOT_FOUND') return null;
    rethrow;
  }
});

final participationSubmitProvider =
    FutureProvider.family<Participation, String>((ref, campaignId) async {
  watchAppRealtimeTick(ref);
  final api = ref.read(apiClientProvider);
  try {
    return await api.fetchParticipationByCampaign(campaignId);
  } on ApiException catch (e) {
    if (e.code == 'NOT_FOUND') {
      return api.joinCampaign(campaignId);
    }
    rethrow;
  }
});
