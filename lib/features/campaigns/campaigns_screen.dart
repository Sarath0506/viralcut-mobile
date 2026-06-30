import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/layout/app_spacing.dart';
import '../../core/layout/list_entrance.dart';
import 'campaign_providers.dart';
import '../../theme/viralcut_colors.dart';
import 'widgets/campaign_list_card.dart';

class CampaignsScreen extends ConsumerStatefulWidget {
  const CampaignsScreen({super.key});

  @override
  ConsumerState<CampaignsScreen> createState() => _CampaignsScreenState();
}

class _CampaignsScreenState extends ConsumerState<CampaignsScreen>
    with SingleTickerProviderStateMixin, ListEntranceAnimationMixin {
  @override
  void dispose() {
    disposeListEntrance();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final campaigns = ref.watch(campaignsProvider);
    final vc = ViralCutColors.of(context);

    return campaigns.when(
      loading: () => const ScreenLoader(),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('$e', textAlign: TextAlign.center),
        ),
      ),
      data: (list) {
        if (list.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'No live campaigns right now.\nPull to refresh later.',
                textAlign: TextAlign.center,
                style: TextStyle(color: vc.muted),
              ),
            ),
          );
        }

        final listKey = list.map((c) => c.id).join(',');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) playListEntrance(listKey);
        });

        return RefreshIndicator(
          onRefresh: () async {
            invalidateListEntrance();
            ref.invalidate(campaignsProvider);
          },
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenHorizontal,
              AppSpacing.md,
              AppSpacing.screenHorizontal,
              AppSpacing.floatingNavBottom(context),
            ),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final c = list[i];
              return ListStaggerEntrance(
                index: i,
                animation: listEntranceController,
                child: CampaignListCard(
                  campaign: c,
                  onTap: () => context.push('/campaigns/${c.id}'),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
