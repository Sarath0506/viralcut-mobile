import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/format/money_format.dart';
import '../../theme/token_colors.dart';

final campaignsProvider = FutureProvider<List<Campaign>>((ref) async {
  return ref.read(apiClientProvider).fetchCampaigns();
});

class CampaignsScreen extends ConsumerWidget {
  const CampaignsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaigns = ref.watch(campaignsProvider);
    final money = Theme.of(context).brightness == Brightness.dark
        ? ViralCutTokenColors.moneyDark
        : ViralCutTokenColors.moneyLight;

    return Scaffold(
      appBar: AppBar(title: const Text('Campaigns')),
      body: campaigns.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(campaignsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final c = list[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      if (c.category != null)
                        Text(c.category!, style: TextStyle(color: Colors.grey.shade600)),
                      const SizedBox(height: 8),
                      Text(
                        c.ratePer1kDisplay,
                        style: TextStyle(
                          color: money,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text('Up to ${formatPaise(c.maxPayoutPaise)}'),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: c.poolPercent / 100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      Text('${c.poolPercent}% pool used'),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => context.push('/campaigns/${c.id}'),
                        child: const Text('Start earning'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
