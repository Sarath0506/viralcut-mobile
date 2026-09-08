import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/realtime/participation_realtime.dart';

/// Clip Marketplace (listing a clip for other creators to repost) is hidden
/// from creators for now — we don't yet have Instagram's permissions to
/// support reposting. Backend/data model stay fully intact; flip this back
/// on once those permissions are in place.
const bool kClipMarketplaceEnabled = false;

/// Keyed by (campaignId, creatorProfileId) — browse is gated server-side on
/// the exact profile that joined the campaign, not just any of the
/// creator's profiles, so both must be provided explicitly by the caller.
final marketplaceListingsProvider = FutureProvider.family<
    List<MarketplaceListing>, (String campaignId, String creatorProfileId)>(
  (ref, args) async {
    watchAppRealtimeTick(ref);
    return ref
        .read(apiClientProvider)
        .fetchMarketplaceListings(args.$1, args.$2);
  },
);
