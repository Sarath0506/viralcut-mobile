import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/campaign/platform_labels.dart';
import '../../../core/participation/participation_models.dart';
import '../../../core/participation/participation_status_labels.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../theme/halchal_colors.dart';
import '../../campaigns/widgets/campaign_shared_widgets.dart';

class SubmissionListCard extends StatelessWidget {
  const SubmissionListCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  static const _thumbSize = 96.0;

  final ParticipationListItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final vc = HalchalColors.of(context);
    final metaLine = submissionListMetaLine(item);

    return Semantics(
      button: true,
      label:
          '${item.campaignTitle}, ${participationSummaryLabel(item.summary)}, $metaLine',
      child: Material(
        color: vc.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: vc.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: _thumbSize,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SquareMediaThumbnail(
                  size: SubmissionListCard._thumbSize,
                  imageUrl: item.coverImageUrl,
                  fallbackImageUrl: item.brandLogoUrl,
                  fallbackLetter: item.campaignTitle,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.campaignTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: vc.onSurface,
                            height: 1.12,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            StatusPill(status: item.summary),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  submissionActionIcon(item.deliverables),
                                  size: 11,
                                  color: vc.muted,
                                ),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    metaLine,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: vc.muted,
                                      height: 1.1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: vc.muted.withValues(alpha: 0.65),
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

String submissionListMetaLine(ParticipationListItem item) {
  final deliverables = item.deliverables;
  final parts = <String>[];

  final profile = item.creatorProfile;
  if (profile != null) {
    parts.add('@${profile.handle}');
  }

  if (deliverables.length == 1) {
    parts.add(formatPlatformLabel(deliverables.first.platform));
  } else if (deliverables.length > 1) {
    parts.add('${deliverables.length} formats');
  } else if (item.platforms.isNotEmpty) {
    parts.add(formatPlatformList(item.platforms));
  }

  final hint = submissionActionHint(deliverables);
  if (hint != null) {
    parts.add(hint);
  }

  return parts.isEmpty ? 'Tap to view' : parts.join(' · ');
}

IconData submissionActionIcon(List<FormatDeliverable> deliverables) {
  if (deliverables.any((d) => d.isRejected)) {
    return Icons.report_problem_outlined;
  }
  if (deliverables.any((d) => d.isDraftPending)) {
    return Icons.upload_file_outlined;
  }
  if (deliverables.any((d) => d.isApproved)) {
    return Icons.link_rounded;
  }
  if (deliverables.any((d) => d.isUnderReview)) {
    return Icons.hourglass_top_rounded;
  }
  if (deliverables.isNotEmpty &&
      deliverables.every((d) => d.isLiveSubmitted)) {
    return Icons.check_circle_outline_rounded;
  }
  return Icons.info_outline_rounded;
}

String? submissionActionHint(List<FormatDeliverable> deliverables) {
  final rejected = deliverables.where((d) => d.isRejected).length;
  if (rejected > 0) {
    return rejected == 1 ? '1 needs changes' : '$rejected need changes';
  }

  final pending = deliverables.where((d) => d.isDraftPending).length;
  if (pending > 0) {
    return pending == 1 ? '1 draft pending' : '$pending drafts pending';
  }

  final approved = deliverables.where((d) => d.isApproved).length;
  if (approved > 0) {
    return approved == 1 ? 'Submit live proof' : '$approved need live proof';
  }

  final review = deliverables.where((d) => d.isUnderReview).length;
  if (review > 0) {
    return review == 1 ? 'Under review' : '$review under review';
  }

  final live = deliverables.where((d) => d.isLiveSubmitted).length;
  if (live > 0 && live == deliverables.length) {
    return 'Proof submitted';
  }

  return null;
}
