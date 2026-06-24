import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/api_client.dart';
import '../../../core/campaign/media_url.dart';
import '../../../core/format/money_format.dart';
import '../../../theme/viralcut_colors.dart';
import 'campaign_shared_widgets.dart';

class CampaignDetailBody extends StatelessWidget {
  const CampaignDetailBody({super.key, required this.campaign});

  final Campaign campaign;

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
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 104),
      children: [
        _HeroCard(campaign: c),
        const SizedBox(height: 18),
        const _SectionTitle('Campaign brief'),
        const SizedBox(height: 8),
        _ContentCard(
          child: Text(
            c.displayBrief ?? 'No brief provided yet.',
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.42,
              color: vc.onSurface,
            ),
          ),
        ),
        if (c.doRuleLines.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionTitle('Things to do', color: vc.money),
          const SizedBox(height: 8),
          _BulletCard(lines: c.doRuleLines, bulletColor: vc.money),
        ],
        if (c.avoidRuleLines.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionTitle('Things to avoid', color: vc.error),
          const SizedBox(height: 8),
          _BulletCard(lines: c.avoidRuleLines, bulletColor: vc.error),
        ],
        if (c.productUrl != null && c.productUrl!.trim().isNotEmpty) ...[
          const SizedBox(height: 16),
          _LinkCard(
            label: 'View product details',
            subtitle: null,
            icon: Icons.link,
            onTap: () => _openUrl(context, c.productUrl!),
          ),
        ],
        if (c.referenceAssets.isNotEmpty) ...[
          const SizedBox(height: 20),
          const _SectionTitle('Brand aesthetics'),
          const SizedBox(height: 10),
          SizedBox(
            height: 132,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: c.referenceAssets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final asset = c.referenceAssets[i];
                final url = resolveCampaignMediaUrl(asset.url);
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: url != null
                      ? Image.network(
                          url,
                          width: 96,
                          height: 132,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _assetPlaceholder(vc),
                        )
                      : _assetPlaceholder(vc),
                );
              },
            ),
          ),
        ],
        if (c.sourceAssets.isNotEmpty) ...[
          const SizedBox(height: 20),
          const _SectionTitle('Reference links'),
          const SizedBox(height: 8),
          ...c.sourceAssets.map(
            (asset) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _LinkCard(
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

  Widget _assetPlaceholder(ViralCutColors vc) {
    return Container(
      width: 96,
      height: 132,
      color: vc.surfaceVariant,
      child: Icon(Icons.image_outlined, color: vc.muted),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.campaign});

  final Campaign campaign;

  @override
  Widget build(BuildContext context) {
    final vc = ViralCutColors.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final c = campaign;

    return Container(
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: vc.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CampaignCoverImage(campaign: c, height: 112),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CampaignBrandAvatar(campaign: c, radius: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.displayBrand,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: vc.onSurface,
                              height: 1.16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              _MetaChip(label: c.platformLabel),
                              if (c.category != null && c.category!.isNotEmpty)
                                _MetaChip(label: c.category!, color: primary),
                              if (c.isPoolAlmostFull)
                                _MetaChip(label: 'Filling fast', color: vc.warning),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _StatBox(
                        label: 'Rate',
                        value: c.ratePer1kDisplay,
                        valueColor: vc.money,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatBox(
                        label: 'Max payout',
                        value: formatPaise(c.maxPayoutPaise),
                        valueColor: vc.money,
                        alignEnd: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ExcludeSemantics(
                  child: CampaignPoolBar(
                    poolPercent: c.poolPercent,
                    showLabels: true,
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

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final vc = ViralCutColors.of(context);
    final chipColor = color ?? vc.muted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: chipColor,
          height: 1,
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
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
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: vc.muted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: valueColor,
            letterSpacing: 0,
          ),
        ),
      ],
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
        fontSize: 17,
        fontWeight: FontWeight.w800,
        height: 1.24,
        color: color ?? ViralCutColors.of(context).onSurface,
      ),
    );
  }
}

class _ContentCard extends StatelessWidget {
  const _ContentCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final vc = ViralCutColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: vc.border),
      ),
      child: child,
    );
  }
}

class _BulletCard extends StatelessWidget {
  const _BulletCard({required this.lines, required this.bulletColor});

  final List<String> lines;
  final Color bulletColor;

  @override
  Widget build(BuildContext context) {
    final vc = ViralCutColors.of(context);
    return _ContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines
            .map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 7, right: 8),
                      decoration: BoxDecoration(
                        color: bulletColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        line,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          height: 1.36,
                          color: vc.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _LinkCard extends StatelessWidget {
  const _LinkCard({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onTap,
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
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: vc.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: primary, size: 20),
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
                          color: vc.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.open_in_new, size: 16, color: vc.muted),
            ],
          ),
        ),
      ),
    );
  }
}
