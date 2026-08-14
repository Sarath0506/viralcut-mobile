import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../../core/api/api_client.dart';
import '../../../core/campaign/campaign_schedule_label.dart';
import '../../../core/campaign/media_url.dart';
import '../../../core/format/money_format.dart';
import '../../../theme/halchal_colors.dart';
import 'campaign_shared_widgets.dart';

class CampaignDetailBody extends StatefulWidget {
  const CampaignDetailBody({
    super.key,
    required this.campaign,
    this.participation,
  });

  final Campaign campaign;
  final Participation? participation;

  @override
  State<CampaignDetailBody> createState() => _CampaignDetailBodyState();
}

class _CampaignDetailBodyState extends State<CampaignDetailBody> {
  Campaign get campaign => widget.campaign;
  Participation? get participation => widget.participation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final asset in campaign.referenceAssets) {
      if (asset.type == 'video') continue;
      final url = resolveCampaignMediaUrl(asset.url);
      if (url != null) precacheImage(NetworkImage(url), context);
    }
  }

  void _openMediaGallery(BuildContext context, List<CampaignAsset> assets, int initialIndex) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => _FullScreenMediaGallery(assets: assets, initialIndex: initialIndex),
    );
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vc = HalchalColors.of(context);
    final c = campaign;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 104),
      children: [
        _CompactHero(campaign: c),
        const SizedBox(height: 14),
        _LinkRow(
          label: 'View leaderboard',
          icon: Icons.leaderboard_outlined,
          onTap: () => context.push('/campaigns/${c.id}/leaderboard'),
        ),
        if (c.displayBrief != null && c.displayBrief!.trim().isNotEmpty) ...[
          const SizedBox(height: 18),
          const _SectionHeader('The brief'),
          const SizedBox(height: 10),
          _BriefCard(text: c.displayBrief!),
        ],
        if (c.doRuleLines.isNotEmpty || c.avoidRuleLines.isNotEmpty) ...[
          const SizedBox(height: 18),
          const _SectionHeader('Content rules'),
          const SizedBox(height: 10),
        ],
        if (c.doRuleLines.isNotEmpty) ...[
          _RuleCard(
            title: 'DO THIS',
            icon: Icons.check_circle_outline_rounded,
            markIcon: Icons.check_rounded,
            color: vc.money,
            lines: c.doRuleLines,
          ),
        ],
        if (c.avoidRuleLines.isNotEmpty) ...[
          const SizedBox(height: 10),
          _RuleCard(
            title: 'AVOID THIS',
            icon: Icons.cancel_outlined,
            markIcon: Icons.close_rounded,
            color: vc.error,
            lines: c.avoidRuleLines,
          ),
        ],
        if (c.productUrl != null && c.productUrl!.trim().isNotEmpty) ...[
          const SizedBox(height: 18),
          const _SectionHeader('Product'),
          const SizedBox(height: 10),
          _LinkRow(
            label: 'View product details',
            icon: Icons.link,
            onTap: () => _openUrl(context, c.productUrl!),
          ),
        ],
        if (c.referenceAssets.isNotEmpty) ...[
          const SizedBox(height: 18),
          const _SectionHeader('Sample content'),
          const SizedBox(height: 4),
          Text(
            'Get inspired by top creators',
            style: GoogleFonts.inter(fontSize: 12, color: vc.muted),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: c.referenceAssets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final asset = c.referenceAssets[i];
                final url = resolveCampaignMediaUrl(asset.url);
                final isVideo = asset.type == 'video';
                final label = asset.label?.trim();
                return GestureDetector(
                  key: ValueKey(asset.url),
                  onTap: url != null
                      ? () => _openMediaGallery(context, c.referenceAssets, i)
                      : null,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 108,
                      height: 140,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (isVideo)
                            _VideoThumbnail(vc: vc, label: asset.label, url: url)
                          else if (url != null)
                            Image.network(
                              url,
                              fit: BoxFit.cover,
                              loadingBuilder: (_, child, progress) {
                                if (progress == null) return child;
                                return Container(color: vc.surfaceVariant)
                                    .animate(onPlay: (c) => c.repeat())
                                    .shimmer(
                                      duration: 1000.ms,
                                      color: vc.border.withValues(alpha: 0.6),
                                    );
                              },
                              errorBuilder: (_, __, ___) =>
                                  _assetPlaceholder(vc, 108, 140),
                            )
                          else
                            _assetPlaceholder(vc, 108, 140),
                          if (isVideo)
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: const BoxDecoration(
                                  color: Colors.black45,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 15,
                                ),
                              ),
                            ),
                          if (label != null && label.isNotEmpty)
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(8, 22, 8, 8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0),
                                      Colors.black.withValues(alpha: 0.78),
                                    ],
                                  ),
                                ),
                                child: Text(
                                  label,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    height: 1.25,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        if (c.sourceAssets.isNotEmpty) ...[
          const SizedBox(height: 18),
          const _SectionHeader('Asset links'),
          const SizedBox(height: 4),
          Text(
            'Brand assets to use in your content',
            style: GoogleFonts.inter(fontSize: 12, color: vc.muted),
          ),
          const SizedBox(height: 10),
          ...c.sourceAssets.map(
            (asset) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _LinkRow(
                label: asset.label?.isNotEmpty == true
                    ? asset.label!
                    : asset.type == 'youtube'
                        ? 'YouTube reference'
                        : 'Drive reference',
                subtitle: asset.type == 'youtube'
                    ? 'Watch on YouTube'
                    : 'Open in Drive',
                icon: asset.type == 'youtube'
                    ? Icons.play_circle_outline
                    : Icons.folder_outlined,
                iconColor:
                    asset.type == 'youtube' ? const Color(0xFFFF0000) : null,
                onTap: () => _openUrl(context, asset.url),
              ),
            ),
          ),
        ],
        const SizedBox(height: 22),
        _HowToParticipate(campaign: c),
        const SizedBox(height: 22),
        const _TrustBanner(),
      ],
    );
  }

  Widget _assetPlaceholder(HalchalColors vc, double width, double height) {
    return Container(
      width: width,
      height: height,
      color: vc.surfaceVariant,
      child: Icon(Icons.image_outlined, color: vc.muted, size: 20),
    );
  }
}

class _VideoThumbnail extends StatefulWidget {
  const _VideoThumbnail({required this.vc, this.label, this.url});
  final HalchalColors vc;
  final String? label;
  final String? url;

  @override
  State<_VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<_VideoThumbnail>
    with AutomaticKeepAliveClientMixin {
  VideoPlayerController? _controller;

  // Keeps the loaded video frame alive when this tile scrolls out of the
  // horizontal list's viewport — without this, ListView.separated disposes
  // and later recreates the widget, forcing the ~2s reload the user saw
  // every time they scrolled away and back.
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final url = widget.url;
    if (url == null) return;
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    _controller = controller;
    controller.initialize().then((_) {
      if (mounted) setState(() {});
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final vc = widget.vc;
    final controller = _controller;
    final hasFrame = controller != null && controller.value.isInitialized;

    return Container(
      color: vc.surface,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasFrame)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: hasFrame ? 0.1 : 0),
                  Colors.black.withValues(alpha: hasFrame ? 0.55 : 0),
                ],
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: hasFrame ? Colors.black45 : vc.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: hasFrame ? Colors.white : vc.primary,
                  size: 22,
                ),
              ),
              if (widget.label != null && widget.label!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  widget.label!,
                  style: TextStyle(
                    fontSize: 10,
                    color: hasFrame ? Colors.white : vc.muted,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Hero: full-bleed cover image + stats card ─────────────────────────────

class _CompactHero extends StatelessWidget {
  const _CompactHero({
    required this.campaign,
  });

  final Campaign campaign;

  @override
  Widget build(BuildContext context) {
    final vc = HalchalColors.of(context);
    final c = campaign;
    final startLabel = campaignStartDetailLabel(c);
    final statusBanner = _campaignStatusBanner(c.status, vc);
    final poolColor = c.poolPercent >= 50 ? vc.warning : vc.money;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CampaignCoverImage(
                    campaign: c, borderRadius: BorderRadius.zero),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.5, 0.78, 1.0],
                      colors: [
                        Colors.black.withValues(alpha: 0.0),
                        Colors.black.withValues(alpha: 0.18),
                        Colors.black.withValues(alpha: 0.78),
                        Colors.black.withValues(alpha: 0.94),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 18,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (c.isPoolAlmostFull) ...[
                        Row(
                          children: [
                            _PillBadge(
                              label: 'FILLING FAST',
                              color: vc.warning,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                      Text(
                        c.title.toUpperCase(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.1,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _StatsCard(campaign: c, startLabel: startLabel, poolColor: poolColor),
        const SizedBox(height: 12),
        _PlatformCard(platform: c.platform, platformLabel: c.platformLabel),
        if (statusBanner != null) ...[
          const SizedBox(height: 10),
          statusBanner,
        ],
      ],
    );
  }

  Widget? _campaignStatusBanner(String status, HalchalColors vc) {
    if (status == 'paused') {
      return _StatusBanner(
        message: 'Campaign paused — new submissions may be limited',
        color: vc.warning,
        icon: Icons.pause_circle_outline,
      );
    }
    if (status == 'closed') {
      return _StatusBanner(
        message: 'Campaign ended',
        color: vc.muted,
        icon: Icons.lock_outline,
      );
    }
    return null;
  }
}

({String asset, Color color})? _brandMark(String platform) {
  final p = platform.toLowerCase();
  if (p.contains('instagram')) {
    return (
      asset: 'assets/images/platform_instagram.svg',
      color: const Color(0xFFE4405F)
    );
  }
  if (p.contains('youtube')) {
    return (
      asset: 'assets/images/platform_youtube.svg',
      color: const Color(0xFFFF0000)
    );
  }
  if (p.contains('twitter') || p.contains('tweet') || p == 'x') {
    return (asset: 'assets/images/platform_x.svg', color: Colors.black);
  }
  return null;
}

class _PlatformCard extends StatelessWidget {
  const _PlatformCard({required this.platform, required this.platformLabel});

  final String platform;
  final String platformLabel;

  @override
  Widget build(BuildContext context) {
    final vc = HalchalColors.of(context);
    final brand = _brandMark(platform);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: vc.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: vc.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            padding: EdgeInsets.all(brand != null ? 8 : 0),
            decoration: BoxDecoration(
              color: brand?.color ?? vc.primary,
              borderRadius: BorderRadius.circular(11),
            ),
            child: brand != null
                ? SvgPicture.asset(
                    brand.asset,
                    colorFilter:
                        const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                  )
                : const Icon(
                    Icons.video_camera_back_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PLATFORM & FORMAT',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: vc.muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  platformLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: vc.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PillBadge extends StatelessWidget {
  const _PillBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: Colors.white,
          height: 1,
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.campaign,
    required this.startLabel,
    required this.poolColor,
  });

  final Campaign campaign;
  final String? startLabel;
  final Color poolColor;

  @override
  Widget build(BuildContext context) {
    final vc = HalchalColors.of(context);
    final c = campaign;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: vc.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MAX PAYOUT',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: vc.muted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formatPaise(c.maxPayoutPaise),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: vc.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: vc.money.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        c.ratePer1kDisplay,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: vc.money,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _PoolRing(percent: c.poolPercent, color: poolColor),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: vc.border),
          const SizedBox(height: 14),
          Row(
            children: [
              if (startLabel != null)
                Expanded(
                  child: _MetaItem(
                    icon: Icons.event_rounded,
                    label: 'STARTS',
                    value: startLabel!,
                  ),
                ),
              Expanded(
                child: _MetaItem(
                  icon: Icons.sell_rounded,
                  label: 'CATEGORY',
                  value:
                      c.category?.isNotEmpty == true ? c.category! : 'General',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PoolRing extends StatelessWidget {
  const _PoolRing({required this.percent, required this.color});

  final int percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final vc = HalchalColors.of(context);
    return SizedBox(
      width: 76,
      height: 76,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 76,
            height: 76,
            child: CircularProgressIndicator(
              value: (percent / 100).clamp(0.0, 1.0),
              strokeWidth: 7,
              strokeCap: StrokeCap.round,
              backgroundColor: vc.border,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$percent%',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: vc.onSurface,
                ),
              ),
              Text(
                'filled',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: vc.muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final vc = HalchalColors.of(context);
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: vc.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 15, color: vc.primary),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: vc.muted,
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: vc.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.message,
    required this.color,
    required this.icon,
  });

  final String message;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared section pieces ──────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final vc = HalchalColors.of(context);
    return Row(
      children: [
        Container(
          width: 3,
          height: 13,
          decoration: BoxDecoration(
            color: vc.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: vc.onSurface,
          ),
        ),
      ],
    );
  }
}

class _BriefCard extends StatelessWidget {
  const _BriefCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final vc = HalchalColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: vc.border),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -10,
            right: -2,
            child: Text(
              '”',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 64,
                fontWeight: FontWeight.w900,
                color: vc.primary.withValues(alpha: 0.12),
                height: 1,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.5,
                color: vc.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({
    required this.title,
    required this.icon,
    required this.markIcon,
    required this.color,
    required this.lines,
  });

  final String title;
  final IconData icon;
  final IconData markIcon;
  final Color color;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final vc = HalchalColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < lines.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i < lines.length - 1 ? 8 : 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(markIcon, size: 12, color: color),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(
                        lines[i],
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          height: 1.35,
                          color: vc.onSurface,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.label,
    required this.icon,
    required this.onTap,
    this.subtitle,
    this.iconColor,
  });

  final String label;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final vc = HalchalColors.of(context);
    final primary = iconColor ?? Theme.of(context).colorScheme.primary;

    return Material(
      color: vc.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: vc.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: primary, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: vc.onSurface,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: vc.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 20, color: vc.muted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Swipeable full-screen viewer for a campaign's reference assets — opens on
/// whichever tile was tapped and lets the viewer swipe to adjacent images/
/// videos without closing and reopening each one individually.
class _FullScreenMediaGallery extends StatefulWidget {
  const _FullScreenMediaGallery({required this.assets, required this.initialIndex});

  final List<CampaignAsset> assets;
  final int initialIndex;

  @override
  State<_FullScreenMediaGallery> createState() => _FullScreenMediaGalleryState();
}

class _FullScreenMediaGalleryState extends State<_FullScreenMediaGallery> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.assets.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (context, i) {
              final asset = widget.assets[i];
              final url = resolveCampaignMediaUrl(asset.url);
              if (url == null) {
                return const Center(
                  child: Icon(Icons.broken_image_outlined, color: Colors.white54, size: 64),
                );
              }
              return asset.type == 'video'
                  ? _GalleryVideoPage(url: url, isActive: i == _currentIndex)
                  : _GalleryImagePage(url: url);
            },
          ),
          if (widget.assets.length > 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.assets.length, (i) {
                  final active = i == _currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active ? Colors.white : Colors.white38,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 12,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GalleryImagePage extends StatelessWidget {
  const _GalleryImagePage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            url,
            fit: BoxFit.contain,
            loadingBuilder: (_, child, progress) =>
                progress == null ? child : const Center(child: CircularProgressIndicator()),
            errorBuilder: (_, __, ___) => const Icon(
              Icons.broken_image_outlined,
              color: Colors.white54,
              size: 64,
            ),
          ),
        ),
      ),
    );
  }
}

class _GalleryVideoPage extends StatefulWidget {
  const _GalleryVideoPage({required this.url, required this.isActive});

  final String url;
  final bool isActive;

  @override
  State<_GalleryVideoPage> createState() => _GalleryVideoPageState();
}

class _GalleryVideoPageState extends State<_GalleryVideoPage> {
  late final VideoPlayerController _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        if (widget.isActive) _controller.play();
      }).catchError((_) {
        if (mounted) setState(() => _failed = true);
      });
  }

  @override
  void didUpdateWidget(covariant _GalleryVideoPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive && _controller.value.isInitialized) {
      // Only the page currently on screen should play — swiping away pauses
      // it so audio doesn't keep running behind the newly visible page.
      widget.isActive ? _controller.play() : _controller.pause();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Center(
          child: _failed
              ? const Icon(
                  Icons.error_outline,
                  color: Colors.white54,
                  size: 64,
                )
              : _controller.value.isInitialized
                  ? GestureDetector(
                      onTap: _togglePlayback,
                      child: AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            VideoPlayer(_controller),
                            if (!_controller.value.isPlaying)
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: const BoxDecoration(
                                  color: Colors.black45,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 36,
                                ),
                              ),
                          ],
                        ),
                      ),
                    )
                  : const CircularProgressIndicator(),
        ),
        if (_controller.value.isInitialized)
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: VideoProgressIndicator(
              _controller,
              allowScrubbing: true,
              padding: EdgeInsets.zero,
              colors: const VideoProgressColors(
                playedColor: Colors.white,
                bufferedColor: Colors.white30,
                backgroundColor: Colors.white12,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── How it works: horizontal mini cards ────────────────────────────────────

class _HowToParticipate extends StatelessWidget {
  const _HowToParticipate({required this.campaign});
  final Campaign campaign;

  static const _steps = [
    (
      icon: Icons.edit_note_rounded,
      title: 'Apply',
      accent: Color(0xFF7C3AED),
    ),
    (
      icon: Icons.videocam_rounded,
      title: 'Create',
      accent: Color(0xFF4F46E5),
    ),
    (
      icon: Icons.upload_file_rounded,
      title: 'Submit',
      accent: Color(0xFF0EA5E9),
    ),
    (
      icon: Icons.payments_rounded,
      title: 'Get paid',
      accent: Color(0xFF10B981),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final vc = HalchalColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader('How it works'),
        const SizedBox(height: 4),
        Text(
          'Your journey from application to payment',
          style: GoogleFonts.inter(fontSize: 12, color: vc.muted),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 118,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _steps.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) =>
                _MiniStepCard(step: _steps[i], index: i),
          ),
        ),
      ],
    );
  }
}

class _MiniStepCard extends StatelessWidget {
  const _MiniStepCard({required this.step, required this.index});

  final ({IconData icon, String title, Color accent}) step;
  final int index;

  @override
  Widget build(BuildContext context) {
    final vc = HalchalColors.of(context);
    return Container(
      width: 112,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: vc.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: step.accent.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(step.icon, color: step.accent, size: 17),
          ),
          const Spacer(),
          Text(
            '0${index + 1}',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: step.accent,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            step.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: vc.onSurface,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(
          delay: Duration(milliseconds: 60 * index),
          duration: const Duration(milliseconds: 300),
        );
  }
}

// ─── Trust banner ────────────────────────────────────────────────────────────

class _TrustBanner extends StatelessWidget {
  const _TrustBanner();

  @override
  Widget build(BuildContext context) {
    final vc = HalchalColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: vc.deepSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: vc.primary.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.verified_user_rounded,
              color: vc.primary,
              size: 22,
            ),
          ),
          const SizedBox(height: 12),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
              children: [
                TextSpan(
                  text: 'Fair. ',
                  style: TextStyle(color: vc.primaryVariant),
                ),
                const TextSpan(text: 'Transparent. Creator First.'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We value your time and creativity. Payments are processed securely and on time.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: Colors.white.withValues(alpha: 0.65),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
