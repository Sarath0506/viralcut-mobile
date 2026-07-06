import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/api/api_client.dart';
import '../../../core/campaign/campaign_schedule_label.dart';
import '../../../core/format/money_format.dart';
import '../../../theme/viralcut_colors.dart';
import 'campaign_shared_widgets.dart';

enum _Badge { urgent, trending, newCampaign, upcoming, none }

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
    final vc = ViralCutColors.of(context);
    final c = campaign;
    final badge = _resolveBadge(c);
    final urgent = badge == _Badge.urgent;

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
          child: Stack(
            children: [
              Padding(
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
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: badge != _Badge.none ? 54 : 0,
                        ),
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
                            const SizedBox(height: 4),
                            Text(
                              c.ratePer1kDisplay,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: vc.money,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Icon(Icons.payments_outlined,
                                    size: 11, color: vc.muted),
                                const SizedBox(width: 3),
                                Text(
                                  '${formatPaise(c.maxPayoutPaise)} cap',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: vc.muted,
                                    height: 1.1,
                                  ),
                                ),
                                Text(
                                  '  ·  ',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: vc.muted,
                                  ),
                                ),
                                Icon(
                                  urgent
                                      ? Icons.local_fire_department_rounded
                                      : Icons.schedule_rounded,
                                  size: 11,
                                  color: urgent ? vc.warning : vc.muted,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  _scheduleLabel(c),
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: urgent
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: urgent ? vc.warning : vc.muted,
                                    height: 1.1,
                                  ),
                                ),
                              ],
                            ),
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
              if (badge != _Badge.none)
                Positioned(
                  top: 10,
                  right: 10,
                  child: _BadgeChip(badge: badge),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.badge});

  final _Badge badge;

  @override
  Widget build(BuildContext context) {
    final vc = ViralCutColors.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final (label, bg) = switch (badge) {
      _Badge.urgent => ('URGENT', vc.error),
      _Badge.trending => ('TRENDING', primary),
      _Badge.newCampaign => ('NEW', vc.money),
      _Badge.upcoming => ('UPCOMING', const Color(0xFF0284C7)),
      _Badge.none => ('', Colors.transparent),
    };

    // Solid fill so the tag stays legible over any thumbnail image,
    // matching the badge treatment on the dashboard's trending carousel.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 8,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 0.4,
          height: 1,
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
