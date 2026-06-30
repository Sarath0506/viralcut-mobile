import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
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
        return VcScaffold(
          title: 'Submission',
          showBack: true,
          body: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                _SubmissionWorkflowHeader(
                  participation: p,
                  vc: vc,
                ),
                const SizedBox(height: 20),
                Text(
                  'Next actions',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: vc.muted,
                  ),
                ),
                const SizedBox(height: 12),
                // Show View Performance button if any deliverable is proof_approved
                if (p.deliverables.any((d) => d.isProofApproved)) ...[
                  FilledButton.icon(
                    onPressed: () {
                      final approved = p.deliverables.firstWhere(
                        (d) => d.isProofApproved,
                      );
                      context.push(
                        '/participations/${p.id}/performance/${approved.id}',
                      );
                    },
                    icon: const Icon(Icons.bar_chart_rounded, size: 18),
                    label: const Text('View Performance & Earnings'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
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
                    onRefreshed: () =>
                        ref.invalidate(participationDetailProvider(widget.id)),
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

class _SubmissionWorkflowHeader extends StatelessWidget {
  const _SubmissionWorkflowHeader({
    required this.participation,
    required this.vc,
  });

  final Participation participation;
  final ViralCutColors vc;

  @override
  Widget build(BuildContext context) {
    final rejected =
        participation.deliverables.where((d) => d.isRejected).length;
    final pending =
        participation.deliverables.where((d) => d.isDraftPending).length;
    final review =
        participation.deliverables.where((d) => d.isUnderReview).length;
    final approved =
        participation.deliverables.where((d) => d.isApproved).length;
    final live =
        participation.deliverables.where((d) => d.hasSubmittedProof).length;
    final proofApproved =
        participation.deliverables.where((d) => d.isProofApproved).length;
    final activeStep = _workflowStep(participation.deliverables);
    final headline = _workflowHeadline(
      rejected: rejected,
      pending: pending,
      review: review,
      approved: approved,
      live: live,
      proofApproved: proofApproved,
    );
    final message = _workflowMessage(
      rejected: rejected,
      pending: pending,
      review: review,
      approved: approved,
      live: live,
      proofApproved: proofApproved,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: vc.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: vc.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  participation.campaign.displayBrand,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: vc.muted,
                  ),
                ),
              ),
              StatusPill(status: participation.summary),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            headline,
            style: GoogleFonts.inter(
              fontSize: 20,
              height: 1.18,
              fontWeight: FontWeight.w800,
              color: vc.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.4,
              color: vc.onSurface.withValues(alpha: 0.78),
            ),
          ),
          const SizedBox(height: 16),
          _WorkflowSteps(activeStep: activeStep, vc: vc),
        ],
      ),
    );
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
    required this.onRefreshed,
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
  final VoidCallback onRefreshed;
  final ViralCutColors vc;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final hint = deliverableStatusHint(deliverable.status);
    final latestReason = deliverable.latestRejectionReason;
    final priorEvents = priorRejectionEvents(deliverable);
    final showHistoryReadOnly =
        deliverable.rejectionHistory.isNotEmpty && !deliverable.isRejected;
    final accent = deliverable.isRejected
        ? vc.error
        : deliverable.isApproved || deliverable.hasSubmittedProof
            ? vc.money
            : deliverable.isUnderReview
                ? vc.warning
                : primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: deliverable.isRejected
              ? vc.error.withValues(alpha: 0.32)
              : vc.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(_statusIcon(deliverable), size: 18, color: accent),
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
              'Brand feedback',
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
                style: GoogleFonts.inter(fontSize: 13, color: vc.error),
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
              label: Text(
                deliverable.isRejected
                    ? 'Open rejected draft'
                    : 'Open approved draft',
              ),
            ),
          ],
          if (deliverable.isRejected) ...[
            const SizedBox(height: 8),
            TextField(
              controller: draftController,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: 'Updated Google Drive draft',
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
                loading ? 'Submitting...' : 'Send updated draft for review',
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
              label: Text(loading ? 'Submitting...' : 'Submit live proof'),
            ),
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
              isProofUnderReview: deliverable.isProofUnderReview,
              vc: vc,
              onRefreshed: onRefreshed,
            ),
          ],
        ],
      ),
    );
  }

  IconData _statusIcon(FormatDeliverable deliverable) {
    if (deliverable.isRejected) return Icons.report_problem_outlined;
    if (deliverable.isApproved) return Icons.publish_outlined;
    if (deliverable.isLiveSubmitted) return Icons.check_circle_outline;
    if (deliverable.isUnderReview) return Icons.hourglass_top_outlined;
    return Icons.upload_file_outlined;
  }
}

class _ProofSubmittedCard extends ConsumerStatefulWidget {
  const _ProofSubmittedCard({
    required this.deliverableId,
    required this.url,
    required this.viewCount,
    required this.vc,
    required this.isProofUnderReview,
    required this.isProofApproved,
    required this.onRefreshed,
    this.submittedAt,
  });

  final String deliverableId;
  final String url;
  final String? submittedAt;
  final int viewCount;
  final bool isProofUnderReview;
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
    final statusLabel =
        widget.isProofApproved ? 'Proof approved' : 'Under brand review';
    final statusIcon = widget.isProofApproved
        ? Icons.check_circle_outline_rounded
        : Icons.hourglass_top_rounded;

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
                Icon(statusIcon, size: 15, color: statusColor),
                const SizedBox(width: 6),
                Text(
                  statusLabel,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
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
                      ? '${_formatViews(displayViews)} views'
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

  String _formatViews(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return '$v';
  }
}

class _WorkflowSteps extends StatelessWidget {
  const _WorkflowSteps({required this.activeStep, required this.vc});

  final int activeStep;
  final ViralCutColors vc;

  static const _steps = ['Draft', 'Review', 'Proof', 'Verified'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          return Expanded(
            child: Container(
              height: 2,
              color: i ~/ 2 < activeStep
                  ? vc.primary
                  : vc.border.withValues(alpha: 0.7),
            ),
          );
        }
        final stepIndex = i ~/ 2;
        final active = stepIndex <= activeStep;
        return Column(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? vc.primary : vc.surface,
                shape: BoxShape.circle,
                border: Border.all(color: active ? vc.primary : vc.border),
              ),
              child: Text(
                '${stepIndex + 1}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: active ? vc.onPrimary : vc.muted,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _steps[stepIndex],
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: active ? vc.onSurface : vc.muted,
              ),
            ),
          ],
        );
      }),
    );
  }
}

int _workflowStep(List<FormatDeliverable> deliverables) {
  if (deliverables.any((d) => d.isProofApproved)) return 3;
  if (deliverables.any((d) => d.isProofUnderReview || d.isLiveSubmitted)) return 2;
  if (deliverables.any((d) => d.isApproved)) return 2;
  if (deliverables.any((d) => d.isUnderReview)) return 1;
  return 0;
}

String _workflowHeadline({
  required int rejected,
  required int pending,
  required int review,
  required int approved,
  required int live,
  required int proofApproved,
}) {
  if (proofApproved > 0 && rejected == 0 && approved == 0 && live == proofApproved) {
    return 'Proof approved — awaiting payout';
  }
  if (rejected > 0 && approved > 0) {
    return '$rejected draft ${rejected == 1 ? 'needs' : 'need'} changes';
  }
  if (rejected > 0) {
    return '$rejected draft ${rejected == 1 ? 'was' : 'were'} rejected';
  }
  if (approved > 0) {
    return '$approved format${approved == 1 ? '' : 's'} ready for proof';
  }
  if (review > 0) return 'Drafts are under brand review';
  if (live > 0) return 'Proof under brand review';
  return pending > 0 ? 'Upload your draft links' : 'Submission';
}

String _workflowMessage({
  required int rejected,
  required int pending,
  required int review,
  required int approved,
  required int live,
  required int proofApproved,
}) {
  if (proofApproved > 0 && live == proofApproved) {
    return 'The brand has verified your live post. Payout will be processed shortly.';
  }
  final parts = <String>[];
  if (rejected > 0) {
    parts.add('Update the rejected draft with a new Drive link.');
  }
  if (approved > 0) {
    parts.add(
      'Post the approved ${approved == 1 ? 'format' : 'formats'} and submit live links.',
    );
  }
  if (review > 0) {
    parts.add('Wait for the brand to finish reviewing drafts under review.');
  }
  if (pending > 0) {
    parts.add('Add the missing draft ${pending == 1 ? 'link' : 'links'}.');
  }
  if (parts.isEmpty && live > 0) {
    parts.add('Your live proof is being reviewed by the brand.');
  }
  return parts.join(' ');
}
