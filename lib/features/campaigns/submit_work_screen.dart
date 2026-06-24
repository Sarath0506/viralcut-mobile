import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/realtime/campaign_realtime_scope.dart';
import '../../core/campaign/platform_labels.dart';
import 'campaign_providers.dart';
import '../../core/participation/rejection_history.dart';
import '../../core/layout/app_spacing.dart';
import '../../core/validation/drive_url.dart';
import '../../core/widgets/status_pill.dart';
import '../../core/widgets/vc_scaffold.dart';
import '../../theme/viralcut_colors.dart';

class SubmitWorkScreen extends ConsumerStatefulWidget {
  const SubmitWorkScreen({super.key, required this.campaignId});

  final String campaignId;

  @override
  ConsumerState<SubmitWorkScreen> createState() => _SubmitWorkScreenState();
}

class _SubmitWorkScreenState extends ConsumerState<SubmitWorkScreen>
    with SingleTickerProviderStateMixin {
  final _controllers = <String, TextEditingController>{};
  final _expandedHistory = <String>{};
  bool _loading = false;
  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _entrance.dispose();
    super.dispose();
  }

  TextEditingController _controllerFor(String deliverableId, String? initial) {
    return _controllers.putIfAbsent(
      deliverableId,
      () => TextEditingController(text: initial ?? ''),
    );
  }

  bool _canSubmitAll(Participation participation) {
    for (final d in participation.deliverables) {
      if (d.isRejected || d.isDraftPending) {
        final url = _controllers[d.id]?.text.trim() ?? '';
        if (!isValidGoogleDriveUrl(url)) return false;
        if (d.isRejected && isSameRejectedDriveUrl(d, url)) return false;
      }
    }
    return participation.deliverables.any(
      (d) => d.isRejected || d.isDraftPending,
    );
  }

  Future<void> _submitDrafts(Participation participation) async {
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      for (final d in participation.deliverables) {
        if (!d.isRejected && !d.isDraftPending) continue;
        final url = _controllers[d.id]?.text.trim() ?? '';
        if (!isValidGoogleDriveUrl(url)) continue;
        if (d.isRejected && isSameRejectedDriveUrl(d, url)) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${formatPlatformLabel(d.platform)}: use a new Drive link — the previous one was rejected.',
              ),
            ),
          );
          return;
        }
        await api.submitDeliverableDraft(
          deliverableId: d.id,
          draftDriveUrl: url,
        );
      }
      ref.invalidate(participationSubmitProvider(widget.campaignId));
      ref.invalidate(campaignParticipationProvider(widget.campaignId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Drafts submitted for review')),
      );
      context.go('/participations/${participation.id}');
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final participation = ref.watch(participationSubmitProvider(widget.campaignId));
    final vc = ViralCutColors.of(context);

    return participation.when(
      loading: () => const VcScaffold(
        title: 'Submit your work',
        showBack: true,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => VcScaffold(
        title: 'Submit your work',
        showBack: true,
        body: Center(child: Text('$e')),
      ),
      data: (p) {
        for (final d in p.deliverables) {
          _controllerFor(d.id, d.draftDriveUrl);
        }

        return CampaignRealtimeScope(
          campaignId: widget.campaignId,
          child: Scaffold(
          backgroundColor: vc.background,
          appBar: AppBar(
            title: Text(p.campaign.displayBrand),
            leading: const BackButton(),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 104),
            children: [
              _StepStrip(activeStep: 0, vc: vc),
              const SizedBox(height: 16),
              Text(
                'Upload one Google Drive draft link for each format.',
                style: TextStyle(color: vc.muted, height: 1.35),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: vc.infoSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: vc.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 18, color: vc.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Drive sharing must be set to Anyone with the link, Viewer.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: vc.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                formatPlatformList(p.campaign.platforms),
                style: TextStyle(
                  color: vc.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              ...p.deliverables.asMap().entries.map((entry) {
                final index = entry.key;
                final d = entry.value;
                final editable = d.isRejected || d.isDraftPending;
                final draftUrl = _controllers[d.id]?.text.trim() ?? '';
                final draftUrlError = draftUrl.isEmpty ? null : driveUrlError(draftUrl);
                final start = index * 0.12;
                final anim = CurvedAnimation(
                  parent: _entrance,
                  curve: Interval(
                    start.clamp(0.0, 0.8),
                    (start + 0.45).clamp(0.0, 1.0),
                    curve: Curves.easeOutCubic,
                  ),
                );

                return FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.08),
                      end: Offset.zero,
                    ).animate(anim),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      formatPlatformLabel(d.platform),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  if (d.rejectionHistory.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: Text(
                                        'Rejected ${d.rejectionHistory.length}×',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: vc.error,
                                        ),
                                      ),
                                    ),
                                  StatusPill(status: d.status),
                                ],
                              ),
                              if (d.latestRejectionReason != null) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: vc.error.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    d.latestRejectionReason!,
                                    style: TextStyle(color: vc.error),
                                  ),
                                ),
                              ],
                              if (priorRejectionEvents(d).isNotEmpty) ...[
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      if (_expandedHistory.contains(d.id)) {
                                        _expandedHistory.remove(d.id);
                                      } else {
                                        _expandedHistory.add(d.id);
                                      }
                                    });
                                  },
                                  child: Row(
                                    children: [
                                      Icon(
                                        _expandedHistory.contains(d.id)
                                            ? Icons.expand_less
                                            : Icons.expand_more,
                                        size: 18,
                                        color: vc.muted,
                                      ),
                                      Text(
                                        'Previous feedback (${priorRejectionEvents(d).length})',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: vc.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_expandedHistory.contains(d.id))
                                  ...priorRejectionEvents(d).map(
                                    (event) => Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: vc.background,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(color: vc.border),
                                        ),
                                        child: Text(event.rejectionReason),
                                      ),
                                    ),
                                  ),
                              ],
                              if (editable) ...[
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _controllerFor(
                                    d.id,
                                    d.draftDriveUrl,
                                  ),
                                  keyboardType: TextInputType.url,
                                  autocorrect: false,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    labelText: 'Google Drive link',
                                    hintText: 'https://drive.google.com/...',
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    errorText: draftUrlError,
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ] else if (d.draftDriveUrl != null) ...[
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: () => launchUrl(
                                    Uri.parse(d.draftDriveUrl!),
                                    mode: LaunchMode.externalApplication,
                                  ),
                                  child: const Text('Open submitted draft'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: AppSpacing.bottomActionPadding(context),
              child: FilledButton(
                onPressed: _loading || !_canSubmitAll(p)
                    ? null
                    : () => _submitDrafts(p),
                child: Text(
                  _loading
                      ? 'Submitting…'
                      : p.deliverables.any((d) => d.isRejected)
                          ? 'Resubmit for review'
                          : 'Submit all drafts for review',
                ),
              ),
            ),
          ),
        ),
        );
      },
    );
  }
}

class _StepStrip extends StatelessWidget {
  const _StepStrip({required this.activeStep, required this.vc});

  final int activeStep;
  final ViralCutColors vc;

  static const _steps = ['Upload drafts', 'Brand review', 'Post & prove'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          return Expanded(
            child: Container(
              height: 2,
              color: i ~/ 2 < activeStep ? vc.primary : vc.border,
            ),
          );
        }
        final stepIndex = i ~/ 2;
        final active = stepIndex <= activeStep;
        return Column(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: active ? vc.primary : vc.surfaceVariant,
              child: Text(
                '${stepIndex + 1}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: active ? vc.onPrimary : vc.muted,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _steps[stepIndex],
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: active ? vc.onSurface : vc.muted,
              ),
            ),
          ],
        );
      }),
    );
  }
}
