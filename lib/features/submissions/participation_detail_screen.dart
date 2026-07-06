import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import 'submission_providers.dart';
import '../../core/campaign/earnings_estimator_card.dart';
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

    return detail.when(
      loading: () => const VcScaffold(
        title: 'Submission Details',
        showBack: true,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => VcScaffold(
        title: 'Submission Details',
        showBack: true,
        body: Center(child: Text('$e')),
      ),
      data: (p) {
        final hasRate = (p.campaign.ratePer1kPaise ?? 0) > 0;
        return VcScaffold(
          title: 'Submission Details',
          showBack: true,
          body: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                _CampaignSummaryCard(participation: p, vc: vc),
                if (hasRate) ...[
                  const SizedBox(height: 16),
                  EarningsEstimatorCard(
                    vc: vc,
                    ratePer1kPaise: p.campaign.ratePer1kPaise,
                    maxPayoutPaise: p.campaign.maxPayoutPaise,
                  ),
                ],
                const SizedBox(height: 20),
                ...p.deliverables.map(
                  (d) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _DeliverableSubmissionCard(
                      participationId: widget.id,
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
                      onSubmitDraft: () => _resubmitDraft(d),
                      onRefreshed: () => ref
                          .invalidate(participationDetailProvider(widget.id)),
                      vc: vc,
                    ),
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

String _formatViewCount(int v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
  return '$v';
}

class _CampaignSummaryCard extends StatelessWidget {
  const _CampaignSummaryCard({required this.participation, required this.vc});

  final Participation participation;
  final ViralCutColors vc;

  @override
  Widget build(BuildContext context) {
    final totalViews =
        participation.deliverables.fold<int>(0, (sum, d) => sum + d.viewCount);
    final joined = DateFormat('d MMM yyyy')
        .format(DateTime.parse(participation.joinedAt).toLocal());

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: vc.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: participation.campaign.brandLogoUrl != null
                ? Image.network(
                    participation.campaign.brandLogoUrl!,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _brandFallbackIcon(),
                  )
                : _brandFallbackIcon(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participation.campaign.displayBrand,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: vc.onSurface,
                  ),
                ),
                Text(
                  participation.campaign.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 12, color: vc.muted),
                ),
                if (participation.creatorProfile != null) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded, size: 11, color: vc.muted),
                      const SizedBox(width: 3),
                      Text(
                        'Submitted as @${participation.creatorProfile!.handle}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: 11, color: vc.muted),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (totalViews > 0) ...[
                      Icon(Icons.visibility_outlined, size: 12, color: vc.muted),
                      const SizedBox(width: 3),
                      Text(
                        _formatViewCount(totalViews),
                        style: GoogleFonts.inter(fontSize: 11, color: vc.muted),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Icon(Icons.calendar_today_outlined, size: 11, color: vc.muted),
                    const SizedBox(width: 3),
                    Text(
                      'Joined $joined',
                      style: GoogleFonts.inter(fontSize: 11, color: vc.muted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _brandFallbackIcon() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: vc.primary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.storefront_rounded, color: vc.primary, size: 22),
    );
  }
}

class _StatusBannerData {
  const _StatusBannerData({
    required this.icon,
    required this.color,
    required this.headline,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String headline;
  final String message;
}

_StatusBannerData _bannerFor(
  FormatDeliverable d,
  ViralCutColors vc,
  String platformLabel,
) {
  switch (d.status) {
    case 'draft_pending':
      return _StatusBannerData(
        icon: Icons.upload_file_outlined,
        color: vc.primary,
        headline: 'Ready for your draft',
        message: 'Upload your $platformLabel draft link to get started.',
      );
    case 'under_review':
      return _StatusBannerData(
        icon: Icons.hourglass_top_rounded,
        color: vc.warning,
        headline: 'Your draft is under review',
        message:
            'The brand is reviewing your submission. We\'ll notify you once they respond.',
      );
    case 'draft_rejected':
      return _StatusBannerData(
        icon: Icons.report_problem_outlined,
        color: vc.error,
        headline: 'Changes requested',
        message: d.latestRejectionReason ??
            'Update your draft with the requested changes and resubmit.',
      );
    case 'draft_approved':
      return _StatusBannerData(
        icon: Icons.check_circle_rounded,
        color: vc.money,
        headline: 'Great news! Your content is approved 🎉',
        message:
            'Your submission has been approved. Now submit the link to your live $platformLabel to receive your payout.',
      );
    case 'live_submitted':
    case 'proof_under_review':
      return _StatusBannerData(
        icon: Icons.hourglass_top_rounded,
        color: vc.warning,
        headline: 'Proof under review',
        message: 'We\'re verifying your live post. This usually takes a day or two.',
      );
    case 'proof_approved':
      return _StatusBannerData(
        icon: Icons.check_circle_rounded,
        color: vc.money,
        headline: 'Proof approved — awaiting payout',
        message: 'The brand has verified your live post. Payout will be processed shortly.',
      );
    case 'proof_rejected':
      return _StatusBannerData(
        icon: Icons.report_problem_outlined,
        color: vc.error,
        headline: 'Proof rejected',
        message: d.latestRejectionReason ??
            'Your live post proof was rejected. Contact support for next steps.',
      );
    default:
      return _StatusBannerData(
        icon: Icons.info_outline_rounded,
        color: vc.muted,
        headline: deliverableStatusLabel(d.status),
        message: '',
      );
  }
}

class _DeliverableSubmissionCard extends StatelessWidget {
  const _DeliverableSubmissionCard({
    required this.participationId,
    required this.deliverable,
    required this.loading,
    required this.liveController,
    required this.draftController,
    required this.historyExpanded,
    required this.onToggleHistory,
    required this.onSubmitLiveProof,
    required this.onSubmitDraft,
    required this.onRefreshed,
    required this.vc,
  });

  final String participationId;
  final FormatDeliverable deliverable;
  final bool loading;
  final TextEditingController liveController;
  final TextEditingController draftController;
  final bool historyExpanded;
  final VoidCallback onToggleHistory;
  final ValueChanged<String> onSubmitLiveProof;
  final VoidCallback onSubmitDraft;
  final VoidCallback onRefreshed;
  final ViralCutColors vc;

  @override
  Widget build(BuildContext context) {
    final platformLabel = formatPlatformLabel(deliverable.platform);
    final banner = _bannerFor(deliverable, vc, platformLabel);
    final priorEvents = priorRejectionEvents(deliverable);
    final showHistoryReadOnly =
        deliverable.rejectionHistory.isNotEmpty && !deliverable.isRejected;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: vc.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  platformLabel,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: vc.onSurface,
                  ),
                ),
              ),
              StatusPill(status: deliverable.status, useDeliverableLabels: true),
            ],
          ),
          const SizedBox(height: 14),

          // Status banner
          if (banner.headline.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: banner.color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: banner.color.withValues(alpha: 0.28)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(banner.icon, size: 18, color: banner.color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          banner.headline,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: banner.color,
                          ),
                        ),
                        if (banner.message.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            banner.message,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              height: 1.4,
                              color: vc.onSurface.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

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
                      historyExpanded ? Icons.expand_less : Icons.expand_more,
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
                        Row(
                          children: [
                            Icon(Icons.history_rounded, size: 12, color: vc.muted),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat.yMMMd().add_jm().format(
                                    DateTime.parse(event.rejectedAt).toLocal(),
                                  ),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: vc.muted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          event.rejectionReason,
                          style: GoogleFonts.inter(fontSize: 13, color: vc.onSurface),
                        ),
                      ],
                    ),
                  ),
                ),
              )),
          ],

          // Under review: show the submitted draft + what happens next
          if (deliverable.isUnderReview && deliverable.draftDriveUrl != null) ...[
            const SizedBox(height: 12),
            _SubmittedDraftCard(
              url: deliverable.draftDriveUrl!,
              submittedAt: deliverable.draftSubmittedAt,
              vc: vc,
            ),
            const SizedBox(height: 12),
            _ReviewTimelineCard(vc: vc),
          ],

          if (deliverable.draftDriveUrl != null &&
              !deliverable.hasSubmittedProof &&
              !deliverable.isUnderReview) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => launchUrl(
                Uri.parse(deliverable.draftDriveUrl!),
                mode: LaunchMode.externalApplication,
              ),
              icon: const Icon(Icons.folder_open_outlined, size: 18),
              label: Text(
                deliverable.isRejected
                    ? 'Open rejected draft'
                    : 'Open approved draft',
              ),
            ),
          ],

          // First-time draft submission (pending)
          if (deliverable.isDraftPending) ...[
            const SizedBox(height: 12),
            Text('Submit your content',
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w700, color: vc.onSurface)),
            const SizedBox(height: 4),
            Text('Paste a Google Drive link to your $platformLabel content.',
                style: GoogleFonts.inter(fontSize: 12, color: vc.muted)),
            const SizedBox(height: 10),
            TextField(
              controller: draftController,
              keyboardType: TextInputType.url,
              autocorrect: false,
              style: TextStyle(color: vc.onSurface),
              decoration: InputDecoration(
                labelText: 'Google Drive link',
                filled: true,
                fillColor: vc.background,
                errorText: driveUrlError(draftController.text),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: loading ? null : onSubmitDraft,
              icon: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text(
                loading ? 'Submitting...' : 'Submit for review',
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            _TipsCard(vc: vc),
          ],

          // Resubmit draft (rejected)
          if (deliverable.isRejected) ...[
            const SizedBox(height: 12),
            Text('Submit your content',
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w700, color: vc.onSurface)),
            const SizedBox(height: 4),
            Text('Paste an updated Google Drive link to your $platformLabel content.',
                style: GoogleFonts.inter(fontSize: 12, color: vc.muted)),
            const SizedBox(height: 10),
            TextField(
              controller: draftController,
              keyboardType: TextInputType.url,
              autocorrect: false,
              style: TextStyle(color: vc.onSurface),
              decoration: InputDecoration(
                labelText: 'Updated Google Drive link',
                filled: true,
                fillColor: vc.background,
                errorText: driveUrlError(draftController.text),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: loading ? null : onSubmitDraft,
              icon: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh, size: 18),
              label: Text(
                loading ? 'Submitting...' : 'Resubmit for review',
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            _TipsCard(vc: vc),
          ],

          // Submit live proof (approved)
          if (deliverable.isApproved) ...[
            const SizedBox(height: 12),
            Text('Submit proof of work',
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w700, color: vc.onSurface)),
            const SizedBox(height: 4),
            Text(
              'Paste the link to your published $platformLabel. Make sure it\'s public and includes the brand as per the brief.',
              style: GoogleFonts.inter(fontSize: 12, color: vc.muted),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: liveController,
              keyboardType: TextInputType.url,
              autocorrect: false,
              style: TextStyle(color: vc.onSurface),
              decoration: InputDecoration(
                labelText: 'Live URL',
                hintText: 'https://…',
                prefixIcon: const Icon(Icons.link_rounded),
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
                  : const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text(
                loading ? 'Submitting...' : 'Submit live link for payout',
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            _TipsCard(vc: vc),
          ],

          if (deliverable.hasSubmittedProof &&
              deliverable.livePostUrl != null) ...[
            const SizedBox(height: 12),
            _ProofSubmittedCard(
              deliverableId: deliverable.id,
              url: deliverable.livePostUrl!,
              submittedAt: deliverable.liveSubmittedAt,
              viewCount: deliverable.viewCount,
              isProofApproved: deliverable.isProofApproved,
              vc: vc,
              onRefreshed: onRefreshed,
            ),
            if (deliverable.isLiveSubmitted || deliverable.isProofUnderReview) ...[
              const SizedBox(height: 12),
              _ReviewTimelineCard(
                vc: vc,
                steps: const [
                  (label: 'Live link submitted', done: true),
                  (label: 'Brand verifies your live post', done: false),
                  (label: 'Payout is processed', done: false),
                ],
                note: 'Verification usually takes 1-2 business days.',
              ),
            ],
          ],

          if (deliverable.isProofApproved) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => context.push(
                '/participations/$participationId/performance/${deliverable.id}',
              ),
              icon: const Icon(Icons.bar_chart_rounded, size: 18),
              label: const Text('View Performance & Earnings'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SubmittedDraftCard extends StatelessWidget {
  const _SubmittedDraftCard({
    required this.url,
    required this.submittedAt,
    required this.vc,
  });

  final String url;
  final String? submittedAt;
  final ViralCutColors vc;

  @override
  Widget build(BuildContext context) {
    final submittedDate = submittedAt != null
        ? DateFormat('dd MMM yyyy, hh:mm a')
            .format(DateTime.parse(submittedAt!).toLocal())
        : null;

    return Container(
      decoration: BoxDecoration(
        color: vc.warning.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: vc.warning.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                Icon(Icons.folder_open_outlined, size: 15, color: vc.warning),
                const SizedBox(width: 6),
                Text(
                  'Your submitted draft',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: vc.warning,
                  ),
                ),
                if (submittedDate != null) ...[
                  const Spacer(),
                  Text(
                    submittedDate,
                    style: GoogleFonts.inter(fontSize: 11, color: vc.muted),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    url,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: vc.onSurface.withValues(alpha: 0.75),
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => launchUrl(
                    Uri.parse(url),
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: Icon(Icons.open_in_new_rounded,
                      size: 18, color: vc.warning),
                  tooltip: 'Open draft',
                  style: IconButton.styleFrom(
                    backgroundColor: vc.warning.withValues(alpha: 0.10),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewTimelineCard extends StatelessWidget {
  const _ReviewTimelineCard({
    required this.vc,
    this.steps = const [
      (label: 'Draft submitted', done: true),
      (label: 'Brand reviews your content', done: false),
      (label: "You'll be notified either way", done: false),
    ],
    this.note = 'This usually takes 1-2 business days.',
  });

  final ViralCutColors vc;
  final List<({String label, bool done})> steps;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: vc.surfaceVariant.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: vc.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What happens next',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: vc.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          for (final step in steps)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    step.done
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked,
                    size: 15,
                    color: step.done ? vc.money : vc.muted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      step.label,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: step.done ? vc.onSurface : vc.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Text(
            note,
            style: GoogleFonts.inter(fontSize: 11, color: vc.muted),
          ),
        ],
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  const _TipsCard({required this.vc});

  final ViralCutColors vc;

  static const _tips = [
    'Make sure your content is public and accessible',
    'Include the product and follow the content rules from the brief',
    'Do not delete or archive your post until it\'s verified',
    'You\'ll be notified as soon as it\'s reviewed',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: vc.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: vc.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: vc.primary, size: 16),
              const SizedBox(width: 6),
              Text('Submission tips',
                  style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w700, color: vc.primary)),
            ],
          ),
          const SizedBox(height: 8),
          ..._tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_rounded, size: 13, color: vc.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(tip,
                        style: GoogleFonts.inter(fontSize: 12, color: vc.onSurface)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProofSubmittedCard extends ConsumerStatefulWidget {
  const _ProofSubmittedCard({
    required this.deliverableId,
    required this.url,
    required this.viewCount,
    required this.vc,
    required this.isProofApproved,
    required this.onRefreshed,
    this.submittedAt,
  });

  final String deliverableId;
  final String url;
  final String? submittedAt;
  final int viewCount;
  final bool isProofApproved;
  final VoidCallback onRefreshed;
  final ViralCutColors vc;

  @override
  ConsumerState<_ProofSubmittedCard> createState() =>
      _ProofSubmittedCardState();
}

class _ProofSubmittedCardState extends ConsumerState<_ProofSubmittedCard> {
  bool _refreshing = false;
  int? _localViewCount;

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    try {
      final result = await ref
          .read(apiClientProvider)
          .refreshDeliverableViews(widget.deliverableId);
      setState(() => _localViewCount = result['viewCount'] ?? 0);
      widget.onRefreshed();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not refresh views: $e')),
      );
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vc = widget.vc;
    final displayViews = _localViewCount ?? widget.viewCount;
    final submittedDate = widget.submittedAt != null
        ? DateFormat('dd MMM yyyy, hh:mm a')
            .format(DateTime.parse(widget.submittedAt!).toLocal())
        : null;

    final statusColor =
        widget.isProofApproved ? vc.money : vc.warning;

    return Container(
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                Icon(Icons.link_rounded, size: 15, color: statusColor),
                const SizedBox(width: 6),
                Text(
                  'Your live proof',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
                if (submittedDate != null) ...[
                  const Spacer(),
                  Text(
                    'Submitted $submittedDate',
                    style: GoogleFonts.inter(fontSize: 11, color: vc.muted),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          // URL row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.url,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: vc.onSurface.withValues(alpha: 0.75),
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => launchUrl(
                    Uri.parse(widget.url),
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: Icon(Icons.open_in_new_rounded,
                      size: 18, color: statusColor),
                  tooltip: 'View live post',
                  style: IconButton.styleFrom(
                    backgroundColor: statusColor.withValues(alpha: 0.10),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ),
          ),
          // Views row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 2, 12, 10),
            child: Row(
              children: [
                Icon(Icons.visibility_outlined, size: 14, color: vc.muted),
                const SizedBox(width: 5),
                Text(
                  displayViews > 0
                      ? '${_formatViewCount(displayViews)} views'
                      : 'Views not yet fetched',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: displayViews > 0 ? vc.onSurface : vc.muted,
                    fontWeight: displayViews > 0
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _refreshing ? null : _refresh,
                  icon: _refreshing
                      ? SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: vc.muted,
                          ),
                        )
                      : Icon(Icons.refresh_rounded, size: 14, color: vc.muted),
                  label: Text(
                    _refreshing ? 'Fetching...' : 'Refresh views',
                    style: GoogleFonts.inter(fontSize: 11, color: vc.muted),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    minimumSize: Size.zero,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
