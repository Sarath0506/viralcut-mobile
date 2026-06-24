import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/campaign/media_url.dart';
import 'submission_providers.dart';
import '../../core/campaign/platform_labels.dart';
import '../../core/widgets/status_pill.dart';
import '../../theme/viralcut_colors.dart';
import '../campaigns/widgets/campaign_stagger_entrance.dart';

class SubmissionsScreen extends ConsumerStatefulWidget {
  const SubmissionsScreen({super.key});

  @override
  ConsumerState<SubmissionsScreen> createState() => _SubmissionsScreenState();
}

class _SubmissionsScreenState extends ConsumerState<SubmissionsScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  String _tab = 'active';
  late final AnimationController _listEntrance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listEntrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshList());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _listEntrance.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshList();
    }
  }

  void _refreshList() {
    ref.invalidate(participationsProvider(_tab));
    ref.invalidate(participationsProvider('active'));
    ref.invalidate(participationsProvider('completed'));
  }

  @override
  Widget build(BuildContext context) {
    final participations = ref.watch(participationsProvider(_tab));
    final vc = ViralCutColors.of(context);
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Submissions')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'active', label: Text('Active')),
                ButtonSegment(value: 'completed', label: Text('Completed')),
              ],
              selected: {_tab},
              onSelectionChanged: (s) {
                setState(() => _tab = s.first);
                ref.invalidate(participationsProvider(s.first));
              },
            ),
          ),
          Expanded(
            child: participations.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (list) {
                if (list.isEmpty) {
                  return Center(
                    child: Text(
                      'No submissions yet',
                      style: TextStyle(color: vc.muted),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    _refreshList();
                    await ref.read(participationsProvider(_tab).future);
                  },
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final p = list[i];
                      final logoUrl = resolveCampaignMediaUrl(p.brandLogoUrl);

                      return CampaignStaggerEntrance(
                        index: i,
                        animation: _listEntrance,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: vc.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: vc.border),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => context.push('/participations/${p.id}'),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (logoUrl != null)
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundImage: NetworkImage(logoUrl),
                                        )
                                      else
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor:
                                              primary.withValues(alpha: 0.12),
                                          child: Text(
                                            p.displayBrand.isNotEmpty
                                                ? p.displayBrand[0].toUpperCase()
                                                : '?',
                                            style: TextStyle(
                                              color: primary,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              p.displayBrand,
                                              style: GoogleFonts.inter(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 15,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              p.campaignTitle,
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                color: vc.muted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(Icons.chevron_right, color: vc.muted),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  StatusPill(status: p.summary),
                                  const SizedBox(height: 12),
                                  ...p.deliverables.map(
                                    (d) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Text(
                                                  formatPlatformLabel(
                                                    d.platform,
                                                  ),
                                                  style: GoogleFonts.inter(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                if (d.isRejected &&
                                                    d.priorRejectionCount > 0)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                      left: 6,
                                                    ),
                                                    child: Icon(
                                                      Icons.refresh,
                                                      size: 14,
                                                      color: vc.warning,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          StatusPill(
                                            status: d.status,
                                            useDeliverableLabels: true,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
