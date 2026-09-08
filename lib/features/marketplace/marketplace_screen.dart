import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/widgets/vc_scaffold.dart';
import '../../theme/halchal_colors.dart';
import 'marketplace_providers.dart';
import 'widgets/marketplace_video_tile.dart';

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({
    super.key,
    required this.campaignId,
    required this.creatorProfileId,
  });

  final String campaignId;
  final String creatorProfileId;

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  final _repostingIds = <String>{};

  (String, String) get _args => (widget.campaignId, widget.creatorProfileId);

  Future<void> _repost(String sourceDeliverableId) async {
    setState(() => _repostingIds.add(sourceDeliverableId));
    try {
      await ref
          .read(apiClientProvider)
          .repostMarketplaceListing(sourceDeliverableId, widget.creatorProfileId);
      ref.invalidate(marketplaceListingsProvider(_args));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reposted — pending review')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _repostingIds.remove(sourceDeliverableId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final listings = ref.watch(marketplaceListingsProvider(_args));
    final vc = HalchalColors.of(context);

    return VcScaffold(
      title: 'Marketplace',
      showBack: true,
      body: listings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('$e', textAlign: TextAlign.center),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No approved clips are listed in this campaign\'s '
                  'marketplace yet. Check back soon.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 13, color: vc.muted),
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(marketplaceListingsProvider(_args));
              await ref.read(marketplaceListingsProvider(_args).future);
            },
            child: GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 9 / 16,
              ),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final listing = items[i];
                return MarketplaceVideoTile(
                  listing: listing,
                  busy: _repostingIds.contains(listing.sourceDeliverableId),
                  onRepost: () => _repost(listing.sourceDeliverableId),
                  vc: vc,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
