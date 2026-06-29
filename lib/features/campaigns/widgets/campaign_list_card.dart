import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/api/api_client.dart';
import '../../../core/campaign/campaign_schedule_label.dart';
import '../../../core/format/money_format.dart';
import '../../../theme/viralcut_colors.dart';
import 'campaign_shared_widgets.dart';

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
                    padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
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
                                Text(
                                  campaignEndingLabel(c),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: vc.muted,
                                    height: 1.1,
                                  ),
                                ),
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

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.campaign});

  final Campaign campaign;

  @override
  Widget build(BuildContext context) {
    final vc = ViralCutColors.of(context);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CampaignListThumbnail(
          campaign: campaign,
          size: CampaignListCard._thumbSize,
          borderRadius: BorderRadius.zero,
        ),
        if (campaign.isPoolAlmostFull)
          Positioned(
            top: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: vc.warning,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'FAST',
                style: GoogleFonts.inter(
                  fontSize: 7,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
