import 'package:flutter/material.dart';

import '../../theme/viralcut_colors.dart';
import '../format/money_format.dart';

const _presetViews = [10000, 50000, 100000];

class EarningsEstimatorCard extends StatelessWidget {
  const EarningsEstimatorCard({
    super.key,
    required this.vc,
    required this.ratePer1kPaise,
    this.maxPayoutPaise,
  });

  final ViralCutColors vc;
  final int? ratePer1kPaise;
  final int? maxPayoutPaise;

  @override
  Widget build(BuildContext context) {
    final rate = ratePer1kPaise ?? 0;
    if (rate <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: vc.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up_rounded, size: 16, color: vc.primary),
              const SizedBox(width: 6),
              Text('What could you earn?',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: vc.onSurface)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final views in _presetViews) ...[
                Expanded(
                  child: _EstimateTile(
                    views: views,
                    paise: _estimate(views, rate, maxPayoutPaise),
                    vc: vc,
                  ),
                ),
                if (views != _presetViews.last) const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }

  int _estimate(int views, int ratePer1kPaise, int? maxPayoutPaise) {
    final raw = ((views / 1000) * ratePer1kPaise).floor();
    if (maxPayoutPaise != null && maxPayoutPaise > 0) {
      return raw > maxPayoutPaise ? maxPayoutPaise : raw;
    }
    return raw;
  }
}

class _EstimateTile extends StatelessWidget {
  const _EstimateTile({
    required this.views,
    required this.paise,
    required this.vc,
  });

  final int views;
  final int paise;
  final ViralCutColors vc;

  String get _viewsLabel =>
      views >= 1000 ? '${(views / 1000).round()}K views' : '$views views';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: vc.money.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: vc.money.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Text(
            formatPaise(paise),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: vc.money,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _viewsLabel,
            style: TextStyle(fontSize: 10, color: vc.muted),
          ),
        ],
      ),
    );
  }
}
