import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/campaigns/campaign_providers.dart';
import '../../features/dashboard/dashboard_providers.dart';
import '../../features/profile/profile_providers.dart';
import '../../features/submissions/submission_providers.dart';
import '../../features/wallet/wallet_providers.dart';
import 'participation_realtime.dart';

String? campaignIdFromRealtimePayload(Map<String, dynamic> payload) {
  final direct = payload['campaignId'];
  if (direct is String && direct.isNotEmpty) return direct;

  final campaign = payload['campaign'];
  if (campaign is Map) {
    final id = campaign['id'];
    if (id is String && id.isNotEmpty) return id;
  }

  return null;
}

/// Bumps the realtime tick and invalidates all creator-app data caches.
void invalidateAppDataCaches(
  WidgetRef ref, {
  Map<String, dynamic>? payload,
}) {
  ref.read(participationRealtimeTickProvider.notifier).update((n) => n + 1);

  final participationId = payload?['participationId'] as String?;
  final campaignId = payload != null
      ? campaignIdFromRealtimePayload(payload)
      : null;

  if (participationId != null) {
    ref.invalidate(participationDetailProvider(participationId));
  }

  ref.invalidate(campaignsProvider);
  ref.invalidate(participationsProvider('active'));
  ref.invalidate(participationsProvider('completed'));
  ref.invalidate(dashboardProvider);
  ref.invalidate(profileMeProvider);
  ref.invalidate(profileDashboardProvider);
  ref.invalidate(profileActiveSubmissionsProvider);
  ref.invalidate(walletProvider);

  if (campaignId != null) {
    ref.invalidate(campaignDetailProvider(campaignId));
    ref.invalidate(campaignParticipationProvider(campaignId));
    ref.invalidate(participationSubmitProvider(campaignId));
  }
}
