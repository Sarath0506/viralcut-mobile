import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../core/widgets/vc_scaffold.dart';
import '../../theme/halchal_colors.dart';

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

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(participationDetailProvider(widget.id));
    final vc = HalchalColors.of(context);

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
                const SizedBox(height: 20),
                ...p.deliverables.map(
                  (d) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _DeliverableSubmissionCard(
                      participationId: widget.id,
                      campaignId: p.campaignId,
                      deliverable: d,
                      loading: _loadingIds.contains(d.id),
                      liveController: _liveControllerFor(d.id),
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

class _CampaignSummaryCard extends StatelessWidget {
  const _CampaignSummaryCard({required this.participation, required this.vc});

  final Participation participation;
  final HalchalColors vc;

  @override
  Widget build(BuildContext context) {
    final joined = DateFormat('d MMM yyyy')
        .format(DateTime.parse(participation.joinedAt).toLocal());
    final subtitle = participation.creatorProfile != null
        ? '@${participation.creatorProfile!.handle}'
        : participation.campaign.title;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: vc.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: participation.campaign.brandLogoUrl != null
                ? Image.network(
                    participation.campaign.brandLogoUrl!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _brandFallbackIcon(),
                  )
                : _brandFallbackIcon(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participation.campaign.displayBrand,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: vc.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 13, color: vc.muted),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetaPill(
                      icon: Icons.calendar_today_outlined,
                      label: 'Joined $joined',
                      vc: vc,
                    ),
                    _MetaPill(
                      icon: Icons.photo_camera_outlined,
                      label: 'Creator',
                      vc: vc,
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
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: vc.primary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(Icons.storefront_rounded, color: vc.primary, size: 26),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label, required this.vc});

  final IconData icon;
  final String label;
  final HalchalColors vc;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: vc.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: vc.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: vc.muted),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: vc.onSurface.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
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
  HalchalColors vc,
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
    required this.campaignId,
    required this.deliverable,
    required this.loading,
    required this.liveController,
    required this.historyExpanded,
    required this.onToggleHistory,
    required this.onSubmitLiveProof,
    required this.vc,
  });

  final String participationId;
  final String campaignId;
  final FormatDeliverable deliverable;
  final bool loading;
  final TextEditingController liveController;
  final bool historyExpanded;
  final VoidCallback onToggleHistory;
  final ValueChanged<String> onSubmitLiveProof;
  final HalchalColors vc;

  @override
  Widget build(BuildContext context) {
    final platformLabel = formatPlatformLabel(deliverable.platform);
    final banner = _bannerFor(deliverable, vc, platformLabel);
    final priorEvents = priorRejectionEvents(deliverable);
    final showHistoryReadOnly =
        deliverable.rejectionHistory.isNotEmpty && !deliverable.isRejected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(_platformIcon(deliverable.platform), size: 14, color: vc.muted),
            const SizedBox(width: 6),
            Text(
              platformLabel.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: vc.muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (banner.headline.isNotEmpty)
          _HeroBanner(
            banner: banner,
            status: deliverable.status,
            tag: _tagLabel(deliverable.status),
            vc: vc,
          ),

        if (priorEvents.isNotEmpty || showHistoryReadOnly) ...[
          const SizedBox(height: 12),
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
            ...((showHistoryReadOnly ? deliverable.rejectionHistory : priorEvents)
                .map(
              (event) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: vc.surface,
                    borderRadius: BorderRadius.circular(12),
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
                            style: GoogleFonts.inter(fontSize: 11, color: vc.muted),
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

        // Draft link — shown whenever a draft exists and proof hasn't been submitted yet
        if (deliverable.draftDriveUrl != null && !deliverable.hasSubmittedProof) ...[
          const SizedBox(height: 14),
          _LinkRow(
            label: deliverable.isRejected
                ? 'Your rejected draft'
                : deliverable.isUnderReview
                    ? 'Your submitted draft'
                    : 'Your approved draft',
            url: deliverable.draftDriveUrl!,
            color: banner.color,
            vc: vc,
            trailing: _shortSubmittedDate(deliverable.draftSubmittedAt),
          ),
        ],

        // First-time draft submission (pending)
        if (deliverable.isDraftPending) ...[
          const SizedBox(height: 14),
          _PrimaryActionButton(
            icon: Icons.upload_rounded,
            label: 'Submit your work',
            vc: vc,
            onPressed: () => context.push('/campaigns/$campaignId/submit'),
          ),
          const SizedBox(height: 10),
          _TipsExpandable(vc: vc),
        ],

        // Resubmit draft (rejected)
        if (deliverable.isRejected) ...[
          const SizedBox(height: 14),
          _PrimaryActionButton(
            icon: Icons.refresh_rounded,
            label: 'Resubmit your work',
            vc: vc,
            onPressed: () => context.push('/campaigns/$campaignId/submit'),
          ),
          const SizedBox(height: 10),
          _TipsExpandable(vc: vc),
        ],

        // Submit live proof (approved)
        if (deliverable.isApproved) ...[
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: vc.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: vc.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: vc.primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        Icons.send_rounded,
                        size: 16,
                        color: vc.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Submit your live link',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: vc.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Paste the link to your live post so we can verify it and release your payout.',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: vc.muted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: liveController,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: vc.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'https://your-post-link.com',
                    hintStyle:
                        GoogleFonts.inter(fontSize: 14, color: vc.muted),
                    prefixIcon: Icon(Icons.link_rounded, color: vc.primary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        Icons.content_paste_rounded,
                        color: vc.primary,
                      ),
                      tooltip: 'Paste',
                      onPressed: () async {
                        final data = await Clipboard.getData('text/plain');
                        final text = data?.text?.trim();
                        if (text != null && text.isNotEmpty) {
                          liveController.text = text;
                        }
                      },
                    ),
                    filled: true,
                    fillColor: vc.background,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: vc.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: vc.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: vc.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _PrimaryActionButton(
                  icon: Icons.send_rounded,
                  label: loading ? 'Submitting...' : 'Submit for payout',
                  loading: loading,
                  vc: vc,
                  onPressed: () =>
                      onSubmitLiveProof(liveController.text.trim()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _TipsExpandable(vc: vc),
        ],

        if (deliverable.hasSubmittedProof && deliverable.livePostUrl != null) ...[
          const SizedBox(height: 14),
          _LinkRow(
            label: 'Your live proof',
            url: deliverable.livePostUrl!,
            color: banner.color,
            vc: vc,
            trailing: _shortSubmittedDate(deliverable.liveSubmittedAt),
          ),
        ],

        if (deliverable.isProofApproved) ...[
          const SizedBox(height: 14),
          _PrimaryActionButton(
            icon: Icons.bar_chart_rounded,
            label: 'View Performance & Earnings',
            vc: vc,
            onPressed: () => context.push(
              '/participations/$participationId/performance/${deliverable.id}',
            ),
          ),
        ],
      ],
    );
  }
}

IconData _platformIcon(String platform) {
  final p = platform.toLowerCase();
  if (p.contains('instagram')) return Icons.camera_alt_rounded;
  if (p.contains('youtube')) return Icons.smart_display_rounded;
  if (p.contains('twitter') || p.contains('_x') || p == 'x') {
    return Icons.alternate_email_rounded;
  }
  return Icons.videocam_rounded;
}

String _tagLabel(String status) {
  switch (status) {
    case 'draft_pending':
      return 'Pending';
    case 'under_review':
      return 'In Review';
    case 'draft_rejected':
      return 'Changes Needed';
    case 'draft_approved':
      return 'Approved';
    case 'live_submitted':
    case 'proof_under_review':
      return 'In Review';
    case 'proof_approved':
      return 'Proof Approved';
    case 'proof_rejected':
      return 'Rejected';
    default:
      return deliverableStatusLabel(status);
  }
}

String? _shortSubmittedDate(String? iso) {
  if (iso == null) return null;
  return DateFormat('d MMM').format(DateTime.parse(iso).toLocal());
}

({IconData main, IconData badge}) _illustrationIcons(String status) {
  switch (status) {
    case 'draft_pending':
      return (main: Icons.cloud_upload_rounded, badge: Icons.arrow_upward_rounded);
    case 'under_review':
      return (main: Icons.hourglass_top_rounded, badge: Icons.visibility_rounded);
    case 'draft_rejected':
      return (main: Icons.description_rounded, badge: Icons.priority_high_rounded);
    case 'draft_approved':
      return (main: Icons.celebration_rounded, badge: Icons.check_rounded);
    case 'live_submitted':
    case 'proof_under_review':
      return (main: Icons.podcasts_rounded, badge: Icons.hourglass_top_rounded);
    case 'proof_approved':
      return (main: Icons.account_balance_wallet_rounded, badge: Icons.paid_rounded);
    case 'proof_rejected':
      return (main: Icons.report_problem_rounded, badge: Icons.close_rounded);
    default:
      return (main: Icons.info_outline_rounded, badge: Icons.circle);
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({
    required this.banner,
    required this.status,
    required this.tag,
    required this.vc,
  });

  final _StatusBannerData banner;
  final String status;
  final String tag;
  final HalchalColors vc;

  @override
  Widget build(BuildContext context) {
    final color = banner.color;
    final illustration = _illustrationIcons(status);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(vc.surface, color, 0.40)!,
              Color.lerp(vc.surface, color, 0.08)!,
            ],
          ),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              right: -10,
              bottom: -14,
              child: Icon(
                illustration.main,
                size: 68,
                color: color.withValues(alpha: 0.14),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    child: Icon(banner.icon, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tag.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          banner.headline,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: vc.onSurface,
                            height: 1.2,
                          ),
                        ),
                        if (banner.message.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            banner.message,
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              height: 1.4,
                              color: vc.onSurface.withValues(alpha: 0.72),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.label,
    required this.url,
    required this.color,
    required this.vc,
    this.trailing,
  });

  final String label;
  final String url;
  final Color color;
  final HalchalColors vc;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(Icons.link_rounded, size: 17, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: vc.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      trailing != null ? 'Submitted $trailing' : 'Tap to open',
                      style: GoogleFonts.inter(fontSize: 11.5, color: vc.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_outward_rounded,
                    size: 14, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.vc,
    this.loading = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final HalchalColors vc;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [vc.primary, vc.primaryVariant],
        ),
        boxShadow: [
          BoxShadow(
            color: vc.primary.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: loading ? null : onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(icon, color: Colors.white, size: 17),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TipsExpandable extends StatefulWidget {
  const _TipsExpandable({required this.vc});

  final HalchalColors vc;

  @override
  State<_TipsExpandable> createState() => _TipsExpandableState();
}

class _TipsExpandableState extends State<_TipsExpandable> {
  bool _open = false;

  static const _tips = [
    'Make sure your content is public and accessible',
    'Include the product and follow the content rules from the brief',
    'Do not delete or archive your post until it\'s verified',
    'You\'ll be notified as soon as it\'s reviewed',
  ];

  @override
  Widget build(BuildContext context) {
    final vc = widget.vc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, size: 15, color: vc.primary),
                const SizedBox(width: 6),
                Text(
                  'Tips for approval',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: vc.primary,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _open ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: vc.primary,
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity, height: 0),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _tips
                  .map(
                    (tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.check_rounded, size: 13, color: vc.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              tip,
                              style: GoogleFonts.inter(
                                  fontSize: 12.5, color: vc.onSurface),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          crossFadeState: _open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}

