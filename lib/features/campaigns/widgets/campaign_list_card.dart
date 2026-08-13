import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/api/api_client.dart';
import '../../../core/campaign/campaign_schedule_label.dart';
import '../../../core/format/money_format.dart';
import '../../../theme/halchal_colors.dart';
import 'campaign_shared_widgets.dart';

enum _Badge { urgent, trending, newCampaign, upcoming }

_Badge _resolveBadge(Campaign c) {
  final now = DateTime.now();
  final start = resolveCampaignStart(c);

  // Not started yet — show upcoming, skip urgency checks
  if (start != null && start.isAfter(now)) return _Badge.upcoming;

  final end = resolveCampaignEndDate(c);
  final daysLeft = end != null ? end.difference(now).inDays : 999;

  if (c.poolPercent >= 80 || daysLeft <= 2) return _Badge.urgent;

  final created = parseCampaignDate(c.createdAt);
  final isNew = created != null && now.difference(created).inDays <= 3;
  if (isNew) return _Badge.newCampaign;

  return _Badge.trending;
}

String _scheduleLabel(Campaign c) {
  final now = DateTime.now();
  final start = resolveCampaignStart(c);

  // Campaign hasn't started yet
  if (start != null && start.isAfter(now)) {
    final diff = start.difference(now);
    if (diff.inDays >= 1) return 'Starts in ${diff.inDays}d';
    if (diff.inHours >= 1) return 'Starts in ${diff.inHours}h';
    return 'Starting soon';
  }

  // Campaign is live — show time remaining
  final end = resolveCampaignEndDate(c);
  if (end == null || end.isBefore(now)) return 'Ends soon';
  final diff = end.difference(now);
  if (diff.inDays >= 1) {
    return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} left';
  }
  if (diff.inHours >= 1) return '${diff.inHours}h left';
  return 'Ends soon';
}

class CampaignListCard extends StatelessWidget {
  const CampaignListCard({
    super.key,
    required this.campaign,
    required this.onTap,
  });

  static const _thumbSize = 76.0;

  final Campaign campaign;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final vc = HalchalColors.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final c = campaign;
    final badge = _resolveBadge(c);
    // Urgency/freshness folds into the schedule line's color, icon, and an
    // optional prefix instead of a separate corner chip — one visual signal
    // instead of two competing for attention with the payout callout.
    final (badgeIcon, badgeColor, badgePrefix) = switch (badge) {
      _Badge.urgent => (Icons.local_fire_department_rounded, vc.warning, ''),
      _Badge.upcoming => (Icons.schedule_rounded, const Color(0xFF0284C7), ''),
      _Badge.newCampaign => (
          Icons.auto_awesome_rounded,
          vc.money,
          'New · ',
        ),
      _Badge.trending => (Icons.trending_up_rounded, primary, 'Trending · '),
    };

    return Semantics(
      button: true,
      label:
          '${c.title}, ${c.ratePer1kDisplay}, up to ${formatPaise(c.maxPayoutPaise)} max, '
          '${campaignEndingLabel(c)}, ${c.poolPercent}% filled',
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
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _Thumbnail(campaign: c),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        c.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: vc.onSurface,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              vc.money.withValues(alpha: 0.16),
                              vc.money.withValues(alpha: 0.06),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: vc.money.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.payments_rounded,
                              size: 13,
                              color: vc.money,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Earn up to ',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: vc.money,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                formatPaise(c.maxPayoutPaise),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: vc.money,
                                  height: 1.1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: vc.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          c.ratePer1kDisplay,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: vc.primary,
                            height: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(badgeIcon, size: 11, color: badgeColor),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              '$badgePrefix${_scheduleLabel(c)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: badgeColor,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: CampaignPoolBar(
                              poolPercent: c.poolPercent,
                              minHeight: 4,
                              showLabels: false,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${c.poolPercent}% filled',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: vc.muted,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: vc.muted.withValues(alpha: 0.65),
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

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.campaign});

  final Campaign campaign;

  @override
  Widget build(BuildContext context) {
    return CampaignListThumbnail(
      campaign: campaign,
      size: CampaignListCard._thumbSize,
      borderRadius: BorderRadius.zero,
    );
  }
}
