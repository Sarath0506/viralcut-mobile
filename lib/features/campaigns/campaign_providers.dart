import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/creator_profile/creator_profile_providers.dart';
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
  final activeProfile = ref.watch(activeCreatorProfileProvider);
  if (activeProfile == null) return null;
  try {
    return await ref
        .read(apiClientProvider)
        .fetchParticipationByCampaign(campaignId, activeProfile.id);
  } on ApiException catch (e) {
    if (e.code == 'NOT_FOUND') return null;
    rethrow;
  }
});

final campaignLeaderboardProvider =
    FutureProvider.family<Leaderboard, String>((ref, campaignId) async {
  watchAppRealtimeTick(ref);
  final activeProfile = ref.watch(activeCreatorProfileProvider);
  return ref
      .read(apiClientProvider)
      .fetchLeaderboard(campaignId, creatorProfileId: activeProfile?.id);
});

final overallLeaderboardProvider = FutureProvider<OverallLeaderboard>((ref) async {
  watchAppRealtimeTick(ref);
  return ref.read(apiClientProvider).fetchOverallLeaderboard();
});

/// Joins [campaignId] as the creator's active profile, or resumes an
/// existing participation for that same profile if one already exists.
final participationSubmitProvider =
    FutureProvider.family<Participation, String>((ref, campaignId) async {
  watchAppRealtimeTick(ref);
  final activeProfile = ref.watch(activeCreatorProfileProvider);
  if (activeProfile == null) {
    throw ApiException('NO_PROFILE', 'Add a creator profile first');
  }
  final api = ref.read(apiClientProvider);
  try {
    return await api.fetchParticipationByCampaign(campaignId, activeProfile.id);
  } on ApiException catch (e) {
    if (e.code == 'NOT_FOUND') {
      return api.joinCampaign(campaignId, activeProfile.id);
    }
    rethrow;
  }
});
