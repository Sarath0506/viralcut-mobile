import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/campaign/campaign_schedule_label.dart';
import '../../../core/api/api_client.dart';
import '../../../core/format/money_format.dart';
import '../../../theme/viralcut_colors.dart';
import '../../campaigns/widgets/campaign_shared_widgets.dart';

class TrendingCampaignsCarousel extends StatefulWidget {
  const TrendingCampaignsCarousel({
    super.key,
    required this.campaigns,
    required this.onCampaignTap,
    required this.onViewAll,
  });

  final List<Campaign> campaigns;
  final ValueChanged<Campaign> onCampaignTap;
  final VoidCallback onViewAll;

  @override
  State<TrendingCampaignsCarousel> createState() =>
      _TrendingCampaignsCarouselState();
}

class _TrendingCampaignsCarouselState extends State<TrendingCampaignsCarousel> {
  static const _cardWidth = 140.0;

  @override
  Widget build(BuildContext context) {
    final vc = ViralCutColors.of(context);
    final primary = Theme.of(context).colorScheme.primary;

    if (widget.campaigns.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(onViewAll: widget.onViewAll, primary: primary),
          const SizedBox(height: 12),
          Text(
            'No live campaigns yet. Check back soon.',
            style: TextStyle(color: vc.muted),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(onViewAll: widget.onViewAll, primary: primary),
        const SizedBox(height: 12),
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: widget.campaigns.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return _TrendingCampaignCard(
                campaign: widget.campaigns[index],
                onTap: () => widget.onCampaignTap(widget.campaigns[index]),
              ).animate(delay: (index * 100).ms).fade(duration: 500.ms, curve: Curves.easeOut).slideY(begin: 0.05, duration: 500.ms, curve: Curves.easeOut);
            },
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.onViewAll, required this.primary});

  final VoidCallback onViewAll;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final vc = ViralCutColors.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Trending campaigns',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: vc.onSurface,
          ),
        ),
        TextButton(
          onPressed: onViewAll,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'View all',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _TrendingCampaignCard extends StatelessWidget {
  const _TrendingCampaignCard({
    required this.campaign,
    required this.onTap,
  });

  final Campaign campaign;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final vc = ViralCutColors.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final c = campaign;
    final isNew = c.createdAt != null &&
        DateTime.now()
                .difference(DateTime.tryParse(c.createdAt!) ?? DateTime(2000))
                .inDays <=
            3;
    final badgeLabel =
        c.isPoolAlmostFull ? 'Hot 🔥' : isNew ? 'New' : 'Trending 🔥';
    final badgeColor = c.isPoolAlmostFull
        ? vc.warning
        : isNew
            ? vc.money
            : primary;

    return SizedBox(
      width: _TrendingCampaignsCarouselState._cardWidth,
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
            fit: StackFit.expand,
            children: [
              // Full background image
              CampaignCoverImage(campaign: c, height: 168),
              // Gradient overlay
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black54,
                      Colors.black87,
                    ],
                    stops: [0.3, 0.7, 1.0],
                  ),
                ),
              ),
              // Badge
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department, color: Colors.white, size: 10),
                      const SizedBox(width: 4),
                      Text(
                        badgeLabel,
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ).animate(onPlay: (controller) => controller.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.04, 1.04), duration: 1400.ms),
              ),
              // Text content at bottom
              Positioned(
                bottom: 10,
                left: 10,
                right: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.displayBrand,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            formatPaise(c.maxPayoutPaise),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF00E676),
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          campaignEndingLabel(c),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
