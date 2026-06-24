import 'package:flutter/material.dart';

import '../../theme/viralcut_colors.dart';
import '../participation/participation_status_labels.dart';

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.status,
    this.label,
    this.useDeliverableLabels = false,
  });

  final String status;
  final String? label;
  final bool useDeliverableLabels;

  @override
  Widget build(BuildContext context) {
    final vc = ViralCutColors.of(context);
    final displayLabel = label ??
        (useDeliverableLabels
            ? deliverableStatusLabel(status)
            : participationSummaryLabel(status));
    final color = _colorFor(status, vc);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Text(
            displayLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }

  Color _colorFor(String status, ViralCutColors vc) {
    switch (status) {
      case 'live':
      case 'paid':
      case 'approved':
      case 'live_tracking':
      case 'draft_approved':
      case 'live_submitted':
      case 'proof_complete':
        return vc.money;
      case 'rejected':
      case 'draft_rejected':
        return vc.error;
      case 'awaiting_live_link':
      case 'action_required':
        return vc.primary;
      case 'in_review':
      case 'under_review':
      case 'drafts_incomplete':
      case 'joined':
      case 'draft_pending':
        return vc.warning;
      default:
        return vc.muted;
    }
  }
}
