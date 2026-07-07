import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../theme/halchal_colors.dart';

enum _SubmitMethod { drive, device }

class SubmitWorkScreen extends ConsumerStatefulWidget {
  const SubmitWorkScreen({super.key, required this.campaignId});

  final String campaignId;

  @override
  ConsumerState<SubmitWorkScreen> createState() => _SubmitWorkScreenState();
}

class _SubmitWorkScreenState extends ConsumerState<SubmitWorkScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _driveControllers = <String, TextEditingController>{};
  final _expandedHistory = <String>{};
  final _uploadedUrls = <String, String>{};
  final _uploadingIds = <String>{};
  bool _loading = false;
  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final c in _driveControllers.values) {
      c.dispose();
    }
    _entrance.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    ref.invalidate(participationSubmitProvider(widget.campaignId));
    ref.invalidate(campaignParticipationProvider(widget.campaignId));
    await ref.read(participationSubmitProvider(widget.campaignId).future);
  }

  TextEditingController _controllerFor(String id, String? initial) =>
      _driveControllers.putIfAbsent(
        id,
        () => TextEditingController(text: initial ?? ''),
      );

  String _effectiveUrl(FormatDeliverable d) =>
      _uploadedUrls[d.id] ?? _driveControllers[d.id]?.text.trim() ?? '';

  bool _canSubmitAll(Participation p) {
    for (final d in p.deliverables) {
      if (!d.isRejected && !d.isDraftPending) continue;
      final url = _effectiveUrl(d);
      if (url.isEmpty) return false;
      final isDrive = url.startsWith('https://drive.google.com') ||
          url.startsWith('https://docs.google.com');
      if (isDrive && driveUrlError(url) != null) return false;
      if (d.isRejected && isDrive && isSameRejectedDriveUrl(d, url)) {
        return false;
      }
    }
    return p.deliverables.any((d) => d.isRejected || d.isDraftPending);
  }

  Future<void> _submitDrafts(Participation p) async {
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      for (final d in p.deliverables) {
        if (!d.isRejected && !d.isDraftPending) continue;
        final url = _effectiveUrl(d);
        if (url.isEmpty) continue;
        if (d.isRejected && isSameRejectedDriveUrl(d, url)) {
          _showSnack('${formatPlatformLabel(d.platform)}: use a new link — the previous one was rejected.');
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
      _showSnack('Submitted for review!');
      context.go('/participations/${p.id}');
    } on ApiException catch (e) {
      _showSnack(e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static const _videoExtensions = {'mp4', 'mov', 'm4v', 'avi', 'mkv'};

  Future<void> _pickAndUpload(FormatDeliverable d) async {
    final picker = ImagePicker();
    final file = await picker.pickMedia();
    if (file == null) return;

    setState(() => _uploadingIds.add(d.id));
    try {
      final api = ref.read(apiClientProvider);
      final ext = file.name.split('.').last.toLowerCase();
      final isVideo = _videoExtensions.contains(ext);
      final mime = isVideo
          ? (ext == 'mov' ? 'video/quicktime' : 'video/mp4')
          : (ext == 'png' ? 'image/png' : 'image/jpeg');
      final url = await api.uploadDraftFile(
        deliverableId: d.id,
        filePath: file.path,
        fileName: file.name,
        mimeType: mime,
      );
      setState(() => _uploadedUrls[d.id] = url);
      _showSnack('File uploaded successfully');
    } on ApiException catch (e) {
      _showSnack(e.message);
    } catch (e) {
      _showSnack('Upload failed. Please try again.');
    } finally {
      if (mounted) setState(() => _uploadingIds.remove(d.id));
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final participation = ref.watch(participationSubmitProvider(widget.campaignId));
    final vc = HalchalColors.of(context);

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

        final pendingDeliverables =
            p.deliverables.where((d) => d.isRejected || d.isDraftPending).toList();
        final otherDeliverables =
            p.deliverables.where((d) => !d.isRejected && !d.isDraftPending).toList();
        final hasRate = (p.campaign.ratePer1kPaise ?? 0) > 0;

        return CampaignRealtimeScope(
          campaignId: widget.campaignId,
          child: Scaffold(
            backgroundColor: vc.background,
            appBar: AppBar(
              backgroundColor: vc.background,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/submissions'),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Submit your work',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  Text(p.campaign.displayBrand,
                      style: TextStyle(fontSize: 12, color: vc.muted)),
                ],
              ),
            ),
            body: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                    16, 8, 16, AppSpacing.floatingNavBottom(context) + 80),
                children: [
                  if (pendingDeliverables.isNotEmpty) ...[
                    ...pendingDeliverables.asMap().entries.map((e) {
                      final d = e.value;
                      final anim = CurvedAnimation(
                        parent: _entrance,
                        curve: Interval(
                          (e.key * 0.1).clamp(0.0, 0.7),
                          ((e.key * 0.1) + 0.4).clamp(0.0, 1.0),
                          curve: Curves.easeOutCubic,
                        ),
                      );
                      return FadeTransition(
                        opacity: anim,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _DeliverableSubmitCard(
                            deliverable: d,
                            driveController: _controllerFor(d.id, d.draftDriveUrl),
                            uploadedUrl: _uploadedUrls[d.id],
                            isUploading: _uploadingIds.contains(d.id),
                            expandedHistory: _expandedHistory,
                            onExpandHistory: (id) => setState(() {
                              _expandedHistory.contains(id)
                                  ? _expandedHistory.remove(id)
                                  : _expandedHistory.add(id);
                            }),
                            onPickFile: () => _pickAndUpload(d),
                            onRemoveUpload: () => setState(() => _uploadedUrls.remove(d.id)),
                            onChanged: () => setState(() {}),
                            vc: vc,
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    _SubmissionTipsCard(vc: vc),
                  ],
                  if (otherDeliverables.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _sectionHeader(context, vc, 'Other formats', null),
                    const SizedBox(height: 8),
                    ...otherDeliverables.map((d) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _CompletedDeliverableRow(d: d, vc: vc),
                        )),
                  ],
                ],
              ),
            ),
            bottomNavigationBar: pendingDeliverables.isEmpty
                ? null
                : SafeArea(
                    child: Padding(
                      padding: AppSpacing.bottomActionPadding(context),
                      child: FilledButton.icon(
                        onPressed: _loading || !_canSubmitAll(p)
                            ? null
                            : () => _submitDrafts(p),
                        icon: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.arrow_forward_rounded),
                        label: Text(_loading
                            ? 'Submitting...'
                            : p.deliverables.any((d) => d.isRejected)
                                ? 'Resubmit for review'
                                : 'Submit for review'),
                        iconAlignment: IconAlignment.end,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _sectionHeader(
      BuildContext context, HalchalColors vc, String title, String? subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(fontSize: 13, color: vc.muted)),
        ],
      ],
    );
  }
}

class _DeliverableSubmitCard extends StatefulWidget {
  const _DeliverableSubmitCard({
    required this.deliverable,
    required this.driveController,
    required this.uploadedUrl,
    required this.isUploading,
    required this.expandedHistory,
    required this.onExpandHistory,
    required this.onPickFile,
    required this.onRemoveUpload,
    required this.onChanged,
    required this.vc,
  });

  final FormatDeliverable deliverable;
  final TextEditingController driveController;
  final String? uploadedUrl;
  final bool isUploading;
  final Set<String> expandedHistory;
  final void Function(String id) onExpandHistory;
  final VoidCallback onPickFile;
  final VoidCallback onRemoveUpload;
  final VoidCallback onChanged;
  final HalchalColors vc;

  @override
  State<_DeliverableSubmitCard> createState() => _DeliverableSubmitCardState();
}

class _DeliverableSubmitCardState extends State<_DeliverableSubmitCard> {
  _SubmitMethod _method = _SubmitMethod.drive;

  FormatDeliverable get d => widget.deliverable;
  HalchalColors get vc => widget.vc;

  @override
  Widget build(BuildContext context) {
    final draftUrl = widget.driveController.text.trim();
    final draftUrlError =
        draftUrl.isEmpty ? null : driveUrlError(draftUrl);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Heading + status
        Row(
          children: [
            const Expanded(
              child: Text('Work submission',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            StatusPill(status: d.status, useDeliverableLabels: true),
          ],
        ),
        const SizedBox(height: 12),

        // Rejection feedback
        if (d.latestRejectionReason != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: vc.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.report_problem_outlined, size: 16, color: vc.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(d.latestRejectionReason!,
                      style: TextStyle(color: vc.error, fontSize: 13)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        if (priorRejectionEvents(d).isNotEmpty) ...[
          InkWell(
            onTap: () => widget.onExpandHistory(d.id),
            child: Row(children: [
              Icon(
                widget.expandedHistory.contains(d.id)
                    ? Icons.expand_less
                    : Icons.expand_more,
                size: 18,
                color: vc.muted,
              ),
              Text('Previous feedback (${priorRejectionEvents(d).length})',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: vc.muted)),
            ]),
          ),
          if (widget.expandedHistory.contains(d.id))
            ...priorRejectionEvents(d).map((e) => Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: vc.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: vc.border),
                    ),
                    child: Text(e.rejectionReason, style: const TextStyle(fontSize: 13)),
                  ),
                )),
          const SizedBox(height: 10),
        ],

        // Section label
        const Text('Submit your content',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Choose any one of the options below',
            style: TextStyle(fontSize: 12, color: vc.muted)),
        const SizedBox(height: 12),

        // Upload from device option (first)
        _MethodCard(
          selected: _method == _SubmitMethod.device,
          onTap: () => setState(() => _method = _SubmitMethod.device),
          vc: vc,
          icon: Icon(Icons.cloud_upload_outlined, color: vc.primary, size: 24),
          title: 'Upload from device',
          subtitle: 'Upload your content directly',
          child: _method == _SubmitMethod.device
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: widget.uploadedUrl != null
                      ? _UploadedFileRow(
                          url: widget.uploadedUrl!,
                          vc: vc,
                          onRemove: widget.onRemoveUpload,
                        )
                      : _DropZone(
                          isUploading: widget.isUploading,
                          vc: vc,
                          onTap: widget.onPickFile,
                        ),
                )
              : null,
        ),

        const SizedBox(height: 10),

        // Drive link option (second)
        _MethodCard(
          selected: _method == _SubmitMethod.drive,
          onTap: () => setState(() => _method = _SubmitMethod.drive),
          vc: vc,
          icon: _DriveIcon(),
          title: 'Submit Google Drive link',
          badge: 'Recommended',
          subtitle: 'Paste a public Google Drive link to your content',
          child: _method == _SubmitMethod.drive
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: widget.driveController,
                              keyboardType: TextInputType.url,
                              autocorrect: false,
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                isDense: true,
                                hintText: 'Paste your Google Drive link here',
                                hintStyle:
                                    TextStyle(color: vc.muted, fontSize: 13),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                errorText: draftUrlError,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: vc.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: vc.border),
                                ),
                              ),
                              onChanged: (_) => widget.onChanged(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () async {
                              final data =
                                  await Clipboard.getData('text/plain');
                              if (data?.text != null) {
                                widget.driveController.text = data!.text!;
                                widget.onChanged();
                              }
                            },
                            child: Text('Paste',
                                style: TextStyle(
                                    color: vc.primary,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.lock_outline,
                              size: 13, color: vc.muted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Make sure the link is viewable by anyone with the link',
                              style:
                                  TextStyle(fontSize: 11, color: vc.muted),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              : null,
        ),
      ],
    );
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.selected,
    required this.onTap,
    required this.vc,
    required this.icon,
    required this.title,
    this.badge,
    required this.subtitle,
    this.child,
  });

  final bool selected;
  final VoidCallback onTap;
  final HalchalColors vc;
  final Widget icon;
  final String title;
  final String? badge;
  final String subtitle;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: vc.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? vc.primary : vc.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                icon,
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(title,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700)),
                          if (badge != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF22C55E)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(badge!,
                                  style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF16A34A))),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: TextStyle(fontSize: 12, color: vc.muted)),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected ? vc.primary : vc.muted,
                  size: 20,
                ),
              ],
            ),
            if (child != null) child!,
          ],
        ),
      ),
    );
  }
}

class _DropZone extends StatelessWidget {
  const _DropZone({
    required this.isUploading,
    required this.vc,
    required this.onTap,
  });

  final bool isUploading;
  final HalchalColors vc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isUploading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: vc.primary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: vc.primary.withValues(alpha: 0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: isUploading
            ? Column(children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: vc.primary),
                ),
                const SizedBox(height: 10),
                Text('Uploading…',
                    style: TextStyle(fontSize: 13, color: vc.primary)),
              ])
            : Column(children: [
                Icon(Icons.cloud_upload_outlined, size: 32, color: vc.primary),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Tap to upload',
                        style: TextStyle(
                            color: vc.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13),
                      ),
                      TextSpan(
                        text: ' or drag & drop',
                        style: TextStyle(
                            color: vc.onSurface, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Videos up to 500MB (max 5 min) or images up to 20MB',
                  style: TextStyle(fontSize: 11, color: vc.muted),
                ),
              ]),
      ),
    );
  }
}

class _UploadedFileRow extends StatelessWidget {
  const _UploadedFileRow(
      {required this.url, required this.vc, required this.onRemove});

  final String url;
  final HalchalColors vc;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final filename = url.split('/').last.split('?').first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: Color(0xFF16A34A), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              filename,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text('Uploaded', style: TextStyle(fontSize: 11, color: vc.muted)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close_rounded, size: 18, color: vc.muted),
          ),
        ],
      ),
    );
  }
}

class _SubmissionTipsCard extends StatelessWidget {
  const _SubmissionTipsCard({required this.vc});

  final HalchalColors vc;

  static const _tips = [
    'Make sure your content is public and accessible',
    'Follow all the content rules mentioned in the brief',
    'Do not delete your post until the review is complete',
    'You will be notified once your submission is reviewed',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline,
                  color: Color(0xFFF59E0B), size: 18),
              SizedBox(width: 8),
              Text('Submission tips',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF92400E))),
            ],
          ),
          const SizedBox(height: 10),
          ..._tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_rounded,
                      size: 15, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(tip,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF78350F))),
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

class _CompletedDeliverableRow extends StatelessWidget {
  const _CompletedDeliverableRow({required this.d, required this.vc});

  final FormatDeliverable d;
  final HalchalColors vc;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: vc.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(formatPlatformLabel(d.platform),
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          StatusPill(status: d.status, useDeliverableLabels: true),
          if (d.draftDriveUrl != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => launchUrl(
                Uri.parse(d.draftDriveUrl!),
                mode: LaunchMode.externalApplication,
              ),
              child: Icon(Icons.open_in_new, size: 16, color: vc.primary),
            ),
          ],
        ],
      ),
    );
  }
}

class _DriveIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(painter: _DriveIconPainter()),
    );
  }
}

class _DriveIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final blue = Paint()..color = const Color(0xFF4285F4);
    final green = Paint()..color = const Color(0xFF34A853);
    final yellow = Paint()..color = const Color(0xFFFBBC04);

    // Google Drive triangle icon approximation
    final path1 = Path()
      ..moveTo(w * 0.5, 0)
      ..lineTo(w, h * 0.87)
      ..lineTo(w * 0.67, h * 0.87)
      ..lineTo(w * 0.17, 0)
      ..close();
    canvas.drawPath(path1, blue);

    final path2 = Path()
      ..moveTo(0, h * 0.87)
      ..lineTo(w * 0.33, h * 0.87)
      ..lineTo(w * 0.5, h)
      ..lineTo(w * 0.17, h)
      ..close();
    canvas.drawPath(path2, green);

    final path3 = Path()
      ..moveTo(w * 0.67, h * 0.87)
      ..lineTo(w, h * 0.87)
      ..lineTo(w * 0.83, h)
      ..lineTo(w * 0.5, h)
      ..close();
    canvas.drawPath(path3, yellow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
