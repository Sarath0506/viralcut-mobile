import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/campaign/media_url.dart';
import 'submission_providers.dart';
import '../../core/campaign/platform_labels.dart';
import '../../core/participation/participation_status_labels.dart';
import '../../core/participation/rejection_history.dart';
import '../../core/validation/drive_url.dart';
import '../../core/widgets/status_pill.dart';
import '../../core/widgets/vc_scaffold.dart';
import '../../theme/viralcut_colors.dart';

class ParticipationDetailScreen extends ConsumerStatefulWidget {
  const ParticipationDetailScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<ParticipationDetailScreen> createState() =>
      _ParticipationDetailScreenState();
}

class _ParticipationDetailScreenState
    extends ConsumerState<ParticipationDetailScreen>
    with WidgetsBindingObserver {
  final _liveControllers = <String, TextEditingController>{};
  final _draftControllers = <String, TextEditingController>{};
  final _loadingIds = <String>{};
  final _expandedHistory = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final c in _liveControllers.values) {
      c.dispose();
    }
    for (final c in _draftControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(participationDetailProvider(widget.id));
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(participationDetailProvider(widget.id));
    await ref.read(participationDetailProvider(widget.id).future);
  }

  TextEditingController _liveControllerFor(String id) {
    return _liveControllers.putIfAbsent(id, () => TextEditingController());
  }

  TextEditingController _draftControllerFor(
    FormatDeliverable deliverable,
  ) {
    return _draftControllers.putIfAbsent(
      deliverable.id,
      () => TextEditingController(text: deliverable.draftDriveUrl ?? ''),
    );
  }

  Future<void> _submitLiveProof(String deliverableId, String url) async {
    setState(() => _loadingIds.add(deliverableId));
    try {
      await ref.read(apiClientProvider).submitDeliverableLiveProof(
            deliverableId: deliverableId,
            livePostUrl: url,
          );
      ref.invalidate(participationDetailProvider(widget.id));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Live proof submitted')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _loadingIds.remove(deliverableId));
    }
  }

  Future<void> _resubmitDraft(FormatDeliverable deliverable) async {
    final url = _draftControllerFor(deliverable).text.trim();
    if (!isValidGoogleDriveUrl(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid Google Drive link')),
      );
      return;
    }
    if (isSameRejectedDriveUrl(deliverable, url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This Drive link was already rejected. Upload an updated creative or use a new link.',
          ),
        ),
      );
      return;
    }

    setState(() => _loadingIds.add(deliverable.id));
    try {
      await ref.read(apiClientProvider).submitDeliverableDraft(
            deliverableId: deliverable.id,
            draftDriveUrl: url,
          );
      ref.invalidate(participationDetailProvider(widget.id));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${formatPlatformLabel(deliverable.platform)} resubmitted for review',
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _loadingIds.remove(deliverable.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(participationDetailProvider(widget.id));
    final vc = ViralCutColors.of(context);
    final primary = Theme.of(context).colorScheme.primary;

    return detail.when(
      loading: () => const VcScaffold(
        title: 'Submission',
        showBack: true,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => VcScaffold(
        title: 'Submission',
        showBack: true,
        body: Center(child: Text('$e')),
      ),
      data: (p) {
        final message = participationSummaryMessage(p.summary);
        final showResubmit = p.deliverables.any(
          (d) => d.isRejected || d.isDraftPending,
        );

        return VcScaffold(
          title: p.campaign.displayBrand,
          showBack: true,
          body: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                _ParticipationHero(
                  participation: p,
                  primary: primary,
                  vc: vc,
                ),
                const SizedBox(height: 16),
                _StatusBanner(
                  summary: p.summary,
                  message: message,
                  vc: vc,
                ),
                if (showResubmit) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () =>
                        context.push('/campaigns/${p.campaignId}/submit'),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit / resubmit drafts'),
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  'Formats',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: vc.muted,
                  ),
                ),
                const SizedBox(height: 12),
                ...p.deliverables.map(
                  (d) => _DeliverableCard(
                    deliverable: d,
                    loading: _loadingIds.contains(d.id),
                    liveController: _liveControllerFor(d.id),
                    draftController: _draftControllerFor(d),
                    historyExpanded: _expandedHistory.contains(d.id),
                    onToggleHistory: () {
                      setState(() {
                        if (_expandedHistory.contains(d.id)) {
                          _expandedHistory.remove(d.id);
                        } else {
                          _expandedHistory.add(d.id);
                        }
                      });
                    },
                    onSubmitLiveProof: (url) => _submitLiveProof(d.id, url),
                    onResubmitDraft: () => _resubmitDraft(d),
                    vc: vc,
                    primary: primary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ParticipationHero extends StatelessWidget {
  const _ParticipationHero({
    required this.participation,
    required this.primary,
    required this.vc,
  });

  final Participation participation;
  final Color primary;
  final ViralCutColors vc;

  @override
  Widget build(BuildContext context) {
    final logoUrl = resolveCampaignMediaUrl(participation.campaign.brandLogoUrl);
    final brand = participation.campaign.displayBrand;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: vc.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (logoUrl != null)
            CircleAvatar(
              radius: 22,
              backgroundImage: NetworkImage(logoUrl),
            )
          else
            CircleAvatar(
              radius: 22,
              backgroundColor: primary.withValues(alpha: 0.12),
              child: Text(
                brand.isNotEmpty ? brand[0].toUpperCase() : '?',
                style: TextStyle(
                  color: primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participation.campaign.title,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: vc.onSurface,
                  ),
                ),
                if (participation.campaign.ratePer1kDisplay != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    participation.campaign.ratePer1kDisplay!,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: vc.money,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                StatusPill(status: participation.summary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.summary,
    required this.message,
    required this.vc,
  });

  final String summary;
  final String message;
  final ViralCutColors vc;

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) return const SizedBox.shrink();

    final color = _bannerColor(summary, vc);
    final icon = _bannerIcon(summary);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participationSummaryLabel(summary),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.4,
                    color: vc.onSurface.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _bannerColor(String summary, ViralCutColors vc) {
    switch (summary) {
      case 'proof_complete':
        return vc.money;
      case 'action_required':
        return vc.primary;
      case 'closed':
        return vc.muted;
      default:
        return vc.warning;
    }
  }

  IconData _bannerIcon(String summary) {
    switch (summary) {
      case 'proof_complete':
        return Icons.check_circle_outline;
      case 'action_required':
        return Icons.campaign_outlined;
      case 'closed':
        return Icons.lock_outline;
      default:
        return Icons.hourglass_top_outlined;
    }
  }
}

class _DeliverableCard extends StatelessWidget {
  const _DeliverableCard({
    required this.deliverable,
    required this.loading,
    required this.liveController,
    required this.draftController,
    required this.historyExpanded,
    required this.onToggleHistory,
    required this.onSubmitLiveProof,
    required this.onResubmitDraft,
    required this.vc,
    required this.primary,
  });

  final FormatDeliverable deliverable;
  final bool loading;
  final TextEditingController liveController;
  final TextEditingController draftController;
  final bool historyExpanded;
  final VoidCallback onToggleHistory;
  final ValueChanged<String> onSubmitLiveProof;
  final VoidCallback onResubmitDraft;
  final ViralCutColors vc;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final hint = deliverableStatusHint(deliverable.status);
    final latestReason = deliverable.latestRejectionReason;
    final priorEvents = priorRejectionEvents(deliverable);
    final showHistoryReadOnly =
        deliverable.rejectionHistory.isNotEmpty && !deliverable.isRejected;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: vc.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.movie_creation_outlined, size: 18, color: primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  formatPlatformLabel(deliverable.platform),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              StatusPill(
                status: deliverable.status,
                useDeliverableLabels: true,
              ),
            ],
          ),
          if (hint.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              hint,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.4,
                color: vc.muted,
              ),
            ),
          ],
          if (latestReason != null && deliverable.isRejected) ...[
            const SizedBox(height: 10),
            Text(
              'Latest feedback',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: vc.error,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: vc.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                latestReason,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: vc.error,
                ),
              ),
            ),
          ],
          if (priorEvents.isNotEmpty || showHistoryReadOnly) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: onToggleHistory,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      historyExpanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                      size: 18,
                      color: vc.muted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      showHistoryReadOnly
                          ? 'Rejection history (${deliverable.rejectionHistory.length})'
                          : 'Previous feedback (${priorEvents.length})',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: vc.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (historyExpanded)
              ...((showHistoryReadOnly
                      ? deliverable.rejectionHistory
                      : priorEvents)
                  .map(
                (event) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: vc.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: vc.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat.yMMMd().add_jm().format(
                                DateTime.parse(event.rejectedAt).toLocal(),
                              ),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: vc.muted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          event.rejectionReason,
                          style: GoogleFonts.inter(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              )),
          ],
          if (deliverable.draftDriveUrl != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => launchUrl(
                Uri.parse(deliverable.draftDriveUrl!),
                mode: LaunchMode.externalApplication,
              ),
              icon: const Icon(Icons.folder_open_outlined, size: 18),
              label: const Text('Open draft (Drive)'),
            ),
          ],
          if (deliverable.isRejected) ...[
            const SizedBox(height: 8),
            TextField(
              controller: draftController,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: 'New Google Drive link',
                filled: true,
                fillColor: vc.background,
                errorText: driveUrlError(draftController.text),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: loading ? null : onResubmitDraft,
              icon: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh, size: 18),
              label: Text(
                loading
                    ? 'Submitting…'
                    : 'Resubmit ${formatPlatformLabel(deliverable.platform)}',
              ),
            ),
          ],
          if (deliverable.isApproved) ...[
            const SizedBox(height: 8),
            TextField(
              controller: liveController,
              decoration: InputDecoration(
                labelText: 'Live post URL',
                filled: true,
                fillColor: vc.background,
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: loading
                  ? null
                  : () => onSubmitLiveProof(liveController.text.trim()),
              icon: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.link, size: 18),
              label: Text(loading ? 'Submitting…' : 'Submit live proof'),
            ),
          ],
          if (deliverable.isLiveSubmitted && deliverable.livePostUrl != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => launchUrl(
                Uri.parse(deliverable.livePostUrl!),
                mode: LaunchMode.externalApplication,
              ),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('View live post'),
            ),
          ],
        ],
      ),
    );
  }
}
