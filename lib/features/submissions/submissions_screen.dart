import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/layout/app_spacing.dart';
import '../../core/layout/list_entrance.dart';
import '../../theme/halchal_colors.dart';
import 'submission_providers.dart';
import 'widgets/submission_list_card.dart';
import 'widgets/submission_tab_selector.dart';

class SubmissionsScreen extends ConsumerStatefulWidget {
  const SubmissionsScreen({super.key});

  @override
  ConsumerState<SubmissionsScreen> createState() => _SubmissionsScreenState();
}

class _SubmissionsScreenState extends ConsumerState<SubmissionsScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver,
        ListEntranceAnimationMixin {
  String _tab = 'active';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshList());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    disposeListEntrance();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshList();
    }
  }

  void _refreshList() {
    invalidateListEntrance();
    ref.invalidate(participationsProvider(_tab));
    ref.invalidate(participationsProvider('active'));
    ref.invalidate(participationsProvider('completed'));
  }

  @override
  Widget build(BuildContext context) {
    final participations = ref.watch(participationsProvider(_tab));
    final activeList = ref.watch(participationsProvider('active'));
    final completedList = ref.watch(participationsProvider('completed'));
    final vc = HalchalColors.of(context);
    final activeCount = activeList.valueOrNull?.length ?? 0;
    final completedCount = completedList.valueOrNull?.length ?? 0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            AppSpacing.md,
            AppSpacing.screenHorizontal,
            AppSpacing.sm,
          ),
          child: SubmissionTabSelector(
            selectedTab: _tab,
            activeCount: activeCount,
            completedCount: completedCount,
            onTabSelected: (tab) {
              setState(() => _tab = tab);
              invalidateListEntrance();
              ref.invalidate(participationsProvider(tab));
            },
          ),
        ),
        Expanded(
          child: participations.when(
            skipLoadingOnRefresh: true,
            loading: () => const ScreenLoader(),
            error: (e, _) => Center(child: Text('$e')),
            data: (list) {
              if (list.isEmpty) {
                return Center(
                  child: Text(
                    _tab == 'completed'
                        ? 'No completed submissions yet'
                        : 'No active submissions yet',
                    style: TextStyle(color: vc.muted),
                  ),
                );
              }

              final listKey = '$_tab:${list.map((p) => p.id).join(',')}';
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) playListEntrance(listKey);
              });

              return RefreshIndicator(
                onRefresh: () async {
                  _refreshList();
                  await ref.read(participationsProvider(_tab).future);
                },
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.screenHorizontal,
                    AppSpacing.sm,
                    AppSpacing.screenHorizontal,
                    AppSpacing.floatingNavBottom(context),
                  ),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final p = list[i];
                    return ListStaggerEntrance(
                      index: i,
                      animation: listEntranceController,
                      child: SubmissionListCard(
                        item: p,
                        onTap: () => context.push('/participations/${p.id}'),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
