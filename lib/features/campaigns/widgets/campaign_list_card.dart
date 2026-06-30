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

  static const _thumbSize = 96.0;

  final Campaign campaign;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final vc = ViralCutColors.of(context);
    final c = campaign;
    final badge = _resolveBadge(c);

    return Semantics(
      button: true,
      label:
          '${c.title}, ${formatPaise(c.maxPayoutPaise)}, ${campaignEndingLabel(c)}, ${c.poolPercent}% filled',
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
                _Thumbnail(campaign: c),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Title row + badge
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                c.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: vc.onSurface,
                                  height: 1.12,
                                ),
                              ),
                            ),
                            if (badge != _Badge.none) ...[
                              const SizedBox(width: 6),
                              _BadgeChip(badge: badge),
                            ],
                          ],
                        ),
                        // Amount + days left + pool bar
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    formatPaise(c.maxPayoutPaise),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: vc.money,
                                      height: 1.1,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                _DaysLeftPill(label: _scheduleLabel(c), badge: badge),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Expanded(
                                  child: CampaignPoolBar(
                                    poolPercent: c.poolPercent,
                                    minHeight: 4,
                                    showLabels: false,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${c.poolPercent}% filled',
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: vc.muted,
                                    height: 1,
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

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.badge});

  final _Badge badge;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (badge) {
      _Badge.urgent      => ('URGENT',    const Color(0xFFFFEDED), const Color(0xFFDC2626)),
      _Badge.trending    => ('TRENDING',  const Color(0xFFEDE9FE), const Color(0xFF7C3AED)),
      _Badge.newCampaign => ('NEW',       const Color(0xFFDCFCE7), const Color(0xFF16A34A)),
      _Badge.upcoming    => ('UPCOMING',  const Color(0xFFE0F2FE), const Color(0xFF0284C7)),
      _Badge.none        => ('',          Colors.transparent,       Colors.transparent),
    };

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
          color: fg,
          letterSpacing: 0.4,
          height: 1,
        ),
      ),
    );
  }
}

class _DaysLeftPill extends StatelessWidget {
  const _DaysLeftPill({required this.label, required this.badge});

  final String label;
  final _Badge badge;

  @override
  Widget build(BuildContext context) {
    final vc = ViralCutColors.of(context);
    final (pillBg, pillFg) = switch (badge) {
      _Badge.urgent   => (vc.warning.withValues(alpha: 0.12), vc.warning),
      _Badge.upcoming => (const Color(0xFFE0F2FE),             const Color(0xFF0284C7)),
      _           => (vc.surfaceVariant,                   vc.muted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: pillBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            badge == _Badge.upcoming
                ? Icons.schedule_rounded
                : Icons.access_time_rounded,
            size: 9,
            color: pillFg,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: pillFg,
              height: 1,
            ),
          ),
        ],
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
