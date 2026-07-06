import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/api_client.dart';
import '../../../core/campaign/campaign_schedule_label.dart';
import '../../../core/campaign/media_url.dart';
import '../../../core/format/money_format.dart';
import '../../../theme/viralcut_colors.dart';
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

  void _openFullScreenImage(BuildContext context, String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => _FullScreenImageViewer(url: url),
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
    final vc = ViralCutColors.of(context);
    final c = campaign;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 104),
      children: [
        _CompactHero(
          campaign: c,
          participation: participation,
        ),
        const SizedBox(height: 10),
        _DarkStatsBar(campaign: c),
        const SizedBox(height: 12),
        _LinkRow(
          label: 'View leaderboard',
          icon: Icons.leaderboard_outlined,
          onTap: () => context.push('/campaigns/${c.id}/leaderboard'),
        ),
        if (c.displayBrief != null && c.displayBrief!.trim().isNotEmpty) ...[
          const SizedBox(height: 14),
          const _SectionTitle('Brief'),
          const SizedBox(height: 6),
          _SurfaceBlock(
            child: Text(
              c.displayBrief!,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.4,
                color: vc.onSurface,
              ),
            ),
          ),
        ],
        if (c.doRuleLines.isNotEmpty || c.avoidRuleLines.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'CONTENT RULES',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: vc.muted,
            ),
          ),
        ],
        if (c.doRuleLines.isNotEmpty) ...[
          const SizedBox(height: 8),
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
          const SizedBox(height: 12),
          const _SectionTitle('Product'),
          const SizedBox(height: 6),
          _LinkRow(
            label: 'View product details',
            icon: Icons.link,
            onTap: () => _openUrl(context, c.productUrl!),
          ),
        ],
        if (c.referenceAssets.isNotEmpty) ...[
          const SizedBox(height: 12),
          const _SectionTitle('Sample content'),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: c.referenceAssets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final asset = c.referenceAssets[i];
                final url = resolveCampaignMediaUrl(asset.url);
                final isVideo = asset.type == 'video';
                return GestureDetector(
                  onTap: url != null
                      ? () => isVideo
                          ? _openUrl(context, url)
                          : _openFullScreenImage(context, url)
                      : null,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: isVideo
                        ? _VideoThumbnail(vc: vc, label: asset.label)
                        : url != null
                            ? Image.network(
                                url,
                                width: 90,
                                height: 120,
                                fit: BoxFit.cover,
                                loadingBuilder: (_, child, progress) {
                                  if (progress == null) return child;
                                  return Container(
                                    width: 90,
                                    height: 120,
                                    color: vc.surfaceVariant,
                                  )
                                      .animate(onPlay: (c) => c.repeat())
                                      .shimmer(
                                        duration: 1000.ms,
                                        color:
                                            vc.border.withValues(alpha: 0.6),
                                      );
                                },
                                errorBuilder: (_, __, ___) =>
                                    _assetPlaceholder(vc, 90, 120),
                              )
                            : _assetPlaceholder(vc, 90, 120),
                  ),
                );
              },
            ),
          ),
        ],
        if (c.sourceAssets.isNotEmpty) ...[
          const SizedBox(height: 12),
          const _SectionTitle('Source links'),
          const SizedBox(height: 6),
          ...c.sourceAssets.map(
            (asset) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _LinkRow(
                label: asset.label?.isNotEmpty == true
                    ? asset.label!
                    : asset.type == 'youtube'
                        ? 'YouTube reference'
                        : 'Drive reference',
                subtitle: asset.url,
                icon: asset.type == 'youtube'
                    ? Icons.play_circle_outline
                    : Icons.folder_outlined,
                onTap: () => _openUrl(context, asset.url),
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        _HowToParticipate(campaign: c),
      ],
    );
  }

  Widget _assetPlaceholder(ViralCutColors vc, double width, double height) {
    return Container(
      width: width,
      height: height,
      color: vc.surfaceVariant,
      child: Icon(Icons.image_outlined, color: vc.muted, size: 20),
    );
  }
}

class _VideoThumbnail extends StatelessWidget {
  const _VideoThumbnail({required this.vc, this.label});
  final ViralCutColors vc;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      height: 120,
      color: vc.surface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: vc.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.play_arrow_rounded, color: vc.primary, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label?.isNotEmpty == true ? label! : 'Video',
            style: TextStyle(
              fontSize: 10,
              color: vc.muted,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _CompactHero extends StatelessWidget {
  const _CompactHero({
    required this.campaign,
    this.participation,
  });

  static const _coverHeight = 168.0;

  final Campaign campaign;
  final Participation? participation;

  @override
  Widget build(BuildContext context) {
    final vc = ViralCutColors.of(context);
    final c = campaign;
    final subtitle = campaignDetailSubtitle(c);
    final startLabel = campaignStartDetailLabel(c);
    final statusBanner = _campaignStatusBanner(c.status, vc);
    final participationBanner = _participationBanner(participation, vc);

    return Container(
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: vc.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              CampaignCoverImage(
                campaign: c,
                height: _coverHeight,
                borderRadius: BorderRadius.zero,
              ),
              if (c.isPoolAlmostFull)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: vc.warning,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'FILLING FAST',
                      style: GoogleFonts.inter(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: vc.onSurface,
                    height: 1.15,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: vc.muted,
                      height: 1.2,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                _StatStrip(campaign: c),
                const SizedBox(height: 10),
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
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: vc.muted,
                      ),
                    ),
                  ],
                ),
                if (startLabel != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    startLabel,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: vc.muted,
                    ),
                  ),
                ],
                if (statusBanner != null) ...[
                  const SizedBox(height: 8),
                  statusBanner,
                ],
                if (participationBanner != null) ...[
                  const SizedBox(height: 8),
                  participationBanner,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget? _campaignStatusBanner(String status, ViralCutColors vc) {
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

  Widget? _participationBanner(Participation? p, ViralCutColors vc) {
    if (p == null) return null;
    final primary = vc.primary;
    final (message, color, icon) = switch (p.summary) {
      'joined' => (
          'Joined — complete your submission',
          primary,
          Icons.check_circle_outline,
        ),
      'drafts_incomplete' => (
          'Draft in progress — tap Continue below',
          primary,
          Icons.edit_outlined,
        ),
      'in_review' => (
          'In review — tap to view submission',
          vc.muted,
          Icons.hourglass_top_outlined,
        ),
      'action_required' => (
          'Action required — update your submission',
          vc.warning,
          Icons.error_outline,
        ),
      'proof_complete' => (
          'Proof submitted — tap to view',
          vc.money,
          Icons.verified_outlined,
        ),
      'closed' => (
          'Your participation is closed',
          vc.muted,
          Icons.lock_outline,
        ),
      _ => (
          'View your submission',
          vc.muted,
          Icons.inbox_outlined,
        ),
    };
    return _StatusBanner(message: message, color: color, icon: icon);
  }
}

class _StatStrip extends StatelessWidget {
  const _StatStrip({required this.campaign});

  final Campaign campaign;

  @override
  Widget build(BuildContext context) {
    final vc = ViralCutColors.of(context);
    final c = campaign;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: vc.surfaceVariant.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _StatCell(
                icon: Icons.trending_up_rounded,
                label: 'Rate / 1K',
                value: c.ratePer1kDisplay,
                valueColor: vc.money,
              ),
            ),
            VerticalDivider(width: 1, color: vc.border.withValues(alpha: 0.6)),
            Expanded(
              child: _StatCell(
                icon: Icons.payments_rounded,
                label: 'Max payout',
                value: formatPaise(c.maxPayoutPaise),
                valueColor: vc.money,
                alignEnd: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
    this.alignEnd = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final vc = ViralCutColors.of(context);
    final alignment =
        alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (alignEnd) ...[
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: vc.muted,
                    height: 1.1,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(icon, size: 11, color: vc.muted),
              ] else ...[
                Icon(icon, size: 11, color: vc.muted),
                const SizedBox(width: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: vc.muted,
                    height: 1.1,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: alignEnd ? TextAlign.end : TextAlign.start,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: valueColor,
              height: 1.1,
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
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

class _DarkStatsBar extends StatelessWidget {
  const _DarkStatsBar({required this.campaign});

  final Campaign campaign;

  @override
  Widget build(BuildContext context) {
    final c = campaign;
    final poolUsed = c.poolPercent;
    final poolColor = poolUsed >= 80
        ? const Color(0xFFF59E0B)
        : poolUsed >= 50
            ? const Color(0xFFF59E0B)
            : const Color(0xFF22C55E);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: ViralCutColors.of(context).deepSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _DarkStatCell(
                icon: Icons.payments_rounded,
                label: 'Max payout',
                value: formatPaise(c.maxPayoutPaise),
                valueColor: const Color(0xFF22C55E),
              ),
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: Colors.white.withValues(alpha: 0.12),
            ),
            Expanded(
              child: _DarkStatCell(
                icon: Icons.donut_small_rounded,
                label: 'Pool used',
                value: '$poolUsed%',
                valueColor: poolColor,
              ),
            ),
            if (c.category != null && c.category!.isNotEmpty) ...[
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: Colors.white.withValues(alpha: 0.12),
              ),
              Expanded(
                child: _DarkStatCell(
                  icon: Icons.category_rounded,
                  label: 'Category',
                  value: c.category!,
                  valueColor: Colors.white,
                  bold: true,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DarkStatCell extends StatelessWidget {
  const _DarkStatCell({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
    this.bold = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
            color: valueColor,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: Colors.white.withValues(alpha: 0.5)),
            const SizedBox(width: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.5),
                height: 1.1,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: ViralCutColors.of(context).onSurface,
      ),
    );
  }
}

class _SurfaceBlock extends StatelessWidget {
  const _SurfaceBlock({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final vc = ViralCutColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: vc.border),
      ),
      child: child,
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
    final vc = ViralCutColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
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
  });

  final String label;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final vc = ViralCutColors.of(context);
    final primary = Theme.of(context).colorScheme.primary;

    return Material(
      color: vc.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: vc.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: primary, size: 18),
              const SizedBox(width: 8),
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
                        fontWeight: FontWeight.w600,
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
              Icon(Icons.chevron_right, size: 18, color: vc.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _FullScreenImageViewer extends StatelessWidget {
  const _FullScreenImageViewer({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : const Center(child: CircularProgressIndicator()),
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 64,
                  ),
                ),
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
      ),
    );
  }
}

class _HowToParticipate extends StatelessWidget {
  const _HowToParticipate({required this.campaign});
  final Campaign campaign;

  List<({String title, IconData icon})> _steps() {
    return const [
      (icon: Icons.videocam_rounded, title: 'Create your clip'),
      (icon: Icons.upload_file_rounded, title: 'Submit work'),
      (icon: Icons.send_rounded, title: 'Post on social media'),
      (icon: Icons.payments_rounded, title: 'Get paid for views'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final steps = _steps();
    final vc = Theme.of(context).extension<ViralCutColors>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('HOW TO PARTICIPATE',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: vc.muted)),
        const SizedBox(height: 12),
        ...List.generate(steps.length, (i) {
          final step = steps[i];
          final isLast = i == steps.length - 1;
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 38,
                  child: Column(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              vc.primary,
                              vc.primaryVariant,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(11),
                          boxShadow: [
                            BoxShadow(
                              color: vc.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(step.icon, color: Colors.white, size: 16),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            margin: const EdgeInsets.symmetric(vertical: 3),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  vc.primary.withValues(alpha: 0.35),
                                  vc.border,
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                    child: Text(step.title,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
