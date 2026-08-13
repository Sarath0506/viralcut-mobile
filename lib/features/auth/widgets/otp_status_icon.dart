import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../theme/halchal_colors.dart';
import '../../../theme/halchal_text_styles.dart';

enum OtpStatus { idle, verifying, verified }

/// Status readout for the OTP verification flow: a glowing circular lock
/// badge, a 4-checkmark cascade once verified, and a pill button that
/// carries the "Verifying…"/"Verified" state — the single loading/status
/// affordance for the flow (no separate spinner).
class OtpStatusIcon extends StatelessWidget {
  const OtpStatusIcon({super.key, required this.status});

  final OtpStatus status;

  @override
  Widget build(BuildContext context) {
    final vc = HalchalColors.of(context);
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final color = switch (status) {
      OtpStatus.idle => vc.muted,
      OtpStatus.verifying => vc.warning,
      OtpStatus.verified => vc.money,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Badge(status: status, color: color, reduceMotion: reduceMotion),
        if (status == OtpStatus.verified) ...[
          const SizedBox(height: 12),
          _CheckmarkRow(color: vc.money, reduceMotion: reduceMotion),
        ],
        if (status != OtpStatus.idle) ...[
          const SizedBox(height: 16),
          _StatusPill(status: status),
        ],
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.status, required this.color, required this.reduceMotion});

  final OtpStatus status;
  final Color color;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      status == OtpStatus.verified ? Icons.lock_open : Icons.lock_outline,
      size: 24,
      color: color,
    );

    Widget animatedIcon = icon;
    if (!reduceMotion) {
      if (status == OtpStatus.verifying) {
        animatedIcon = icon
            .animate(onPlay: (c) => c.repeat())
            .shake(hz: 3, offset: const Offset(2, 0));
      } else if (status == OtpStatus.verified) {
        animatedIcon = icon.animate().scale(
              begin: const Offset(0.6, 0.6),
              duration: 500.ms,
              curve: Curves.elasticOut,
            );
      }
    }

    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
        boxShadow: status == OtpStatus.idle
            ? null
            : [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 14,
                  spreadRadius: status == OtpStatus.verified ? 2 : 1,
                ),
              ],
      ),
      child: animatedIcon,
    );
  }
}

class _CheckmarkRow extends StatelessWidget {
  const _CheckmarkRow({required this.color, required this.reduceMotion});

  static const _checkCount = 4;

  final Color color;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_checkCount, (i) {
        final check = Icon(Icons.check, size: 14, color: color);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: reduceMotion
              ? check
              : check
                  .animate(delay: (i * 220).ms)
                  .scale(
                    begin: const Offset(0.4, 0.4),
                    duration: 500.ms,
                    curve: Curves.elasticOut,
                  )
                  .fadeIn(duration: 400.ms),
        );
      }),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final OtpStatus status;

  @override
  Widget build(BuildContext context) {
    final vc = HalchalColors.of(context);
    final verifying = status == OtpStatus.verifying;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: verifying ? vc.warningBright : vc.moneyBright,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        verifying ? 'Verifying...' : 'Verified',
        style: HalchalTextStyles.meta(context).copyWith(
          color: vc.deepSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
