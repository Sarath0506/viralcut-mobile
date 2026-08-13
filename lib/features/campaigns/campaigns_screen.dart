import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/campaign/platform_labels.dart';
import '../../core/layout/app_spacing.dart';
import '../../core/layout/list_entrance.dart';
import 'campaign_providers.dart';
import '../../theme/halchal_colors.dart';
import '../submissions/submission_providers.dart';
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
    final result =
        await showModalBottomSheet<({String? platform, bool sortByPayout})>(
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
    final activeParticipations = ref.watch(participationsProvider('active'));
    final completedParticipations =
        ref.watch(participationsProvider('completed'));
    final vc = HalchalColors.of(context);

    final joinedCampaignIds = {
      for (final p in activeParticipations.valueOrNull ?? []) p.campaignId,
      for (final p in completedParticipations.valueOrNull ?? []) p.campaignId,
    };

    return campaigns.when(
      skipLoadingOnRefresh: true,
      loading: () => const ScreenLoader(),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('$e', textAlign: TextAlign.center),
        ),
      ),
      data: (rawList) {
        final list =
            rawList.where((c) => !joinedCampaignIds.contains(c.id)).toList();
        if (list.isEmpty) {
          void refresh() {
            invalidateListEntrance();
            ref.invalidate(campaignsProvider);
            ref.invalidate(participationsProvider('active'));
            ref.invalidate(participationsProvider('completed'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              refresh();
              await ref.read(campaignsProvider.future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: _CampaignsEmptyState(
                    allCaughtUp: rawList.isNotEmpty,
                    onRefresh: refresh,
                  ),
                ),
              ],
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
          final matchesPlatform = _selectedPlatform == null ||
              c.platforms.contains(_selectedPlatform);
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
            ref.invalidate(participationsProvider('active'));
            ref.invalidate(participationsProvider('completed'));
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
                        physics: const AlwaysScrollableScrollPhysics(),
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

class _CampaignsEmptyState extends StatefulWidget {
  const _CampaignsEmptyState({
    required this.allCaughtUp,
    required this.onRefresh,
  });

  /// True when there ARE live campaigns but the creator has already
  /// applied to every one of them — a good-news state, not a dead end.
  final bool allCaughtUp;
  final VoidCallback onRefresh;

  @override
  State<_CampaignsEmptyState> createState() => _CampaignsEmptyStateState();
}

class _CampaignsEmptyStateState extends State<_CampaignsEmptyState>
    with TickerProviderStateMixin {
  // Same entrance + float recipe as the onboarding hero illustrations:
  // a one-time scale/fade pop-in, then a slow continuous bob.
  late final AnimationController _reveal;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  late final AnimationController _float;

  @override
  void initState() {
    super.initState();
    _reveal = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _scale = Tween<double>(begin: 0.9, end: 1).animate(
      CurvedAnimation(parent: _reveal, curve: Curves.easeOutBack),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(_reveal);
    _reveal.forward();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _reveal.dispose();
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vc = HalchalColors.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final allCaughtUp = widget.allCaughtUp;
    final onRefresh = widget.onRefresh;

    final (asset, title, subtitle) = allCaughtUp
        ? (
            'assets/images/campaigns_empty_caught_up.svg',
            "You're all caught up!",
            "You've applied to every live campaign.\nCheck their progress in Submissions, or pull\nto refresh for new ones.",
          )
        : (
            'assets/images/campaigns_empty_none.svg',
            'No live campaigns yet',
            'New brand campaigns drop regularly.\nPull down to refresh, or check back soon.',
          );

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 220,
              height: 190,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  AnimatedBuilder(
                    animation: _float,
                    builder: (context, child) => Transform.scale(
                      scale: 1.0 + 0.04 * _float.value,
                      child: child,
                    ),
                    child: Container(
                      width: 190,
                      height: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(120),
                        gradient: RadialGradient(
                          colors: [
                            primary.withValues(alpha: 0.30),
                            primary.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: Listenable.merge([_reveal, _float]),
                    builder: (context, child) => Opacity(
                      opacity: _fade.value,
                      child: Transform.translate(
                        offset: Offset(0, (_float.value - 0.5) * 6),
                        child: Transform.scale(
                          scale: _scale.value,
                          child: child,
                        ),
                      ),
                    ),
                    child: SvgPicture.asset(asset, width: 220),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: vc.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: vc.muted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            if (allCaughtUp)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => context.go('/submissions'),
                    icon: const Icon(Icons.inventory_2_outlined, size: 16),
                    label: const Text('View submissions'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primary,
                      side: BorderSide(color: primary.withValues(alpha: 0.4)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: onRefresh,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          Icons.refresh_rounded,
                          size: 18,
                          color: primary,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              OutlinedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Refresh'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primary,
                  side: BorderSide(color: primary.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
          ],
        ),
      ),
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
  final HalchalColors vc;
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

  final HalchalColors vc;
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
    final vc = HalchalColors.of(context);

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
