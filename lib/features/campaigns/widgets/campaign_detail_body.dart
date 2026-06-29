import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/api_client.dart';
import '../../../core/campaign/campaign_schedule_label.dart';
import '../../../core/campaign/media_url.dart';
import '../../../core/format/money_format.dart';
import '../../../theme/viralcut_colors.dart';
import 'campaign_shared_widgets.dart';

class CampaignDetailBody extends StatelessWidget {
  const CampaignDetailBody({
    super.key,
    required this.campaign,
    this.participation,
  });

  final Campaign campaign;
  final Participation? participation;

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
        if (c.doRuleLines.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SectionTitle('Do', color: vc.money),
          const SizedBox(height: 6),
          _BulletBlock(lines: c.doRuleLines, bulletColor: vc.money),
        ],
        if (c.avoidRuleLines.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SectionTitle('Avoid', color: vc.error),
          const SizedBox(height: 6),
          _BulletBlock(lines: c.avoidRuleLines, bulletColor: vc.error),
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
          const _SectionTitle('Brand references'),
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: c.referenceAssets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final asset = c.referenceAssets[i];
                final url = resolveCampaignMediaUrl(asset.url);
                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: url != null
                      ? Image.network(
                          url,
                          width: 56,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _assetPlaceholder(vc, 56, 80),
                        )
                      : _assetPlaceholder(vc, 56, 80),
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
                label: 'Rate / 1K',
                value: c.ratePer1kDisplay,
                valueColor: vc.money,
              ),
            ),
            VerticalDivider(width: 1, color: vc.border.withValues(alpha: 0.6)),
            Expanded(
              child: _StatCell(
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
    required this.label,
    required this.value,
    required this.valueColor,
    this.alignEnd = false,
  });

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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: color ?? ViralCutColors.of(context).onSurface,
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

class _BulletBlock extends StatelessWidget {
  const _BulletBlock({required this.lines, required this.bulletColor});

  final List<String> lines;
  final Color bulletColor;

  @override
  Widget build(BuildContext context) {
    final vc = ViralCutColors.of(context);
    return _SurfaceBlock(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < lines.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i < lines.length - 1 ? 6 : 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.only(top: 5, right: 8),
                    decoration: BoxDecoration(
                      color: bulletColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      lines[i],
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        height: 1.35,
                        color: vc.onSurface,
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
