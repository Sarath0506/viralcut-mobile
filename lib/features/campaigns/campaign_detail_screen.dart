import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/format/money_format.dart';
import '../../core/widgets/vc_scaffold.dart';

final campaignDetailProvider =
    FutureProvider.family<Campaign, String>((ref, id) async {
  return ref.read(apiClientProvider).fetchCampaign(id);
});

class CampaignDetailScreen extends ConsumerWidget {
  const CampaignDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaign = ref.watch(campaignDetailProvider(id));

    return campaign.when(
      loading: () => const VcScaffold(
        title: 'Campaign',
        showBack: true,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => VcScaffold(
        title: 'Campaign',
        showBack: true,
        body: Center(child: Text('$e')),
      ),
      data: (c) => VcScaffold(
        title: c.title,
        showBack: true,
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              c.ratePer1kDisplay,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 8),
            Text('Max payout ${formatPaise(c.maxPayoutPaise)}'),
            const SizedBox(height: 16),
            Text(c.brief),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.push('/campaigns/$id/submit'),
              child: const Text('Submit work for review'),
            ),
          ],
        ),
      ),
    );
  }
}
