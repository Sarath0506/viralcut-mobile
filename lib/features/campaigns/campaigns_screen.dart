import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/campaign/platform_labels.dart';
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
  final _searchController = TextEditingController();
  String _query = '';
  String? _selectedPlatform;
  bool _sortByPayout = false;

  @override
  void dispose() {
    _searchController.dispose();
    disposeListEntrance();
    super.dispose();
  }

  Future<void> _openFilterSheet(List<String> availablePlatforms) async {
    final result = await showModalBottomSheet<({String? platform, bool sortByPayout})>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        availablePlatforms: availablePlatforms,
        initialPlatform: _selectedPlatform,
        initialSortByPayout: _sortByPayout,
      ),
    );
    if (result != null) {
      setState(() {
        _selectedPlatform = result.platform;
        _sortByPayout = result.sortByPayout;
      });
    }
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

        final availablePlatforms = <String>{
          for (final c in list) ...c.platforms,
        }.toList()
          ..sort();

        final query = _query.trim().toLowerCase();
        var filtered = list.where((c) {
          final matchesQuery = query.isEmpty ||
              c.title.toLowerCase().contains(query) ||
              (c.brandCompanyName?.toLowerCase().contains(query) ?? false) ||
              (c.category?.toLowerCase().contains(query) ?? false);
          final matchesPlatform =
              _selectedPlatform == null || c.platforms.contains(_selectedPlatform);
          return matchesQuery && matchesPlatform;
        }).toList();

        if (_sortByPayout) {
          filtered = [...filtered]
            ..sort((a, b) => b.maxPayoutPaise.compareTo(a.maxPayoutPaise));
        }

        final listKey =
            '${filtered.map((c) => c.id).join(',')}|$query|$_selectedPlatform|$_sortByPayout';
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) playListEntrance(listKey);
        });

        final activeFilterCount =
            (_selectedPlatform != null ? 1 : 0) + (_sortByPayout ? 1 : 0);

        return RefreshIndicator(
          onRefresh: () async {
            invalidateListEntrance();
            ref.invalidate(campaignsProvider);
          },
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  AppSpacing.md,
                  AppSpacing.screenHorizontal,
                  0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _query = v),
                        decoration: InputDecoration(
                          hintText: 'Search campaigns or brands',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _query.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _query = '');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: vc.surface,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 0, horizontal: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: vc.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: vc.border),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _FilterCornerButton(
                      vc: vc,
                      activeCount: activeFilterCount,
                      onTap: () => _openFilterSheet(availablePlatforms),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'No campaigns match your search.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: vc.muted),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.screenHorizontal,
                          0,
                          AppSpacing.screenHorizontal,
                          AppSpacing.floatingNavBottom(context),
                        ),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final c = filtered[i];
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
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.vc,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ViralCutColors vc;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? primary.withValues(alpha: 0.14) : vc.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? primary : vc.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: selected ? primary : vc.muted),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? primary : vc.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterCornerButton extends StatelessWidget {
  const _FilterCornerButton({
    required this.vc,
    required this.activeCount,
    required this.onTap,
  });

  final ViralCutColors vc;
  final int activeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = activeCount > 0;
    final primary = Theme.of(context).colorScheme.primary;

    return Material(
      color: active ? primary.withValues(alpha: 0.12) : vc.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: active ? primary : vc.border),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.tune_rounded,
                size: 20,
                color: active ? primary : vc.onSurface,
              ),
              if (active)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: vc.background, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.availablePlatforms,
    required this.initialPlatform,
    required this.initialSortByPayout,
  });

  final List<String> availablePlatforms;
  final String? initialPlatform;
  final bool initialSortByPayout;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String? _platform = widget.initialPlatform;
  late bool _sortByPayout = widget.initialSortByPayout;

  @override
  Widget build(BuildContext context) {
    final vc = ViralCutColors.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          20 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: vc.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: vc.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _platform = null;
                    _sortByPayout = false;
                  }),
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Platform',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: vc.muted,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _platform == null,
                  onTap: () => setState(() => _platform = null),
                  vc: vc,
                ),
                for (final p in widget.availablePlatforms)
                  _FilterChip(
                    label: formatPlatformLabel(p),
                    selected: _platform == p,
                    onTap: () => setState(
                      () => _platform = _platform == p ? null : p,
                    ),
                    vc: vc,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Sort',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: vc.muted,
              ),
            ),
            const SizedBox(height: 8),
            _FilterChip(
              label: 'Highest payout first',
              icon: Icons.trending_up_rounded,
              selected: _sortByPayout,
              onTap: () => setState(() => _sortByPayout = !_sortByPayout),
              vc: vc,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                (platform: _platform, sortByPayout: _sortByPayout),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }
}
