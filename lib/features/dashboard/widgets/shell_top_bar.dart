import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/format/money_format.dart';
import '../../../core/layout/app_spacing.dart';
import '../../../theme/viralcut_colors.dart';
import '../../auth/widgets/auth_app_icon.dart';
import '../dashboard_providers.dart';

enum ShellTopBarVariant { home, campaigns, submissions, wallet, profile }

extension ShellTopBarVariantX on ShellTopBarVariant {
  String get title => switch (this) {
        ShellTopBarVariant.home => 'Halchal',
        ShellTopBarVariant.campaigns => 'Campaigns',
        ShellTopBarVariant.submissions => 'Submissions',
        ShellTopBarVariant.wallet => 'Wallet',
        ShellTopBarVariant.profile => 'Profile',
      };
}

ShellTopBarVariant shellTopBarVariantForPath(String path) {
  if (path.startsWith('/profile')) return ShellTopBarVariant.profile;
  if (path.startsWith('/wallet')) return ShellTopBarVariant.wallet;
  if (path.startsWith('/submissions')) return ShellTopBarVariant.submissions;
  if (path.startsWith('/campaigns')) return ShellTopBarVariant.campaigns;
  return ShellTopBarVariant.home;
}

/// Shared top bar for main tab routes (Instagram-style: section chrome, not profile).
class ShellTopBar extends ConsumerWidget {
  const ShellTopBar({super.key, required this.currentPath});

  final String currentPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final variant = shellTopBarVariantForPath(currentPath);

    return SizedBox(
      height: AppSpacing.shellTopBarHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
        child: Row(
          children: [
            Expanded(child: _BrandLeading(variant: variant)),
            _Trailing(variant: variant),
          ],
        ),
      ),
    );
  }
}

class _BrandLeading extends StatelessWidget {
  const _BrandLeading({required this.variant});

  final ShellTopBarVariant variant;

  @override
  Widget build(BuildContext context) {
    final vc = ViralCutColors.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AuthAppIcon.header(),
        const SizedBox(width: AppSpacing.sm),
        Text(
          variant.title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: vc.onSurface,
          ),
        ),
      ],
    );
  }
}

class _Trailing extends ConsumerWidget {
  const _Trailing({required this.variant});

  final ShellTopBarVariant variant;

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vc = ViralCutColors.of(context);

    if (variant == ShellTopBarVariant.home) {
      final dashboard = ref.watch(dashboardProvider);

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          dashboard.when(
            data: (data) => _EarningsChip(lifetimePaise: data.wallet.lifetimePaise),
            loading: () => const SizedBox(
              width: 72,
              height: 32,
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: vc.onSurface),
            tooltip: 'Notifications',
            onPressed: () => _showComingSoon(context, 'Notifications'),
          ),
        ],
      );
    }

    if (variant == ShellTopBarVariant.wallet) {
      return IconButton(
        icon: Icon(Icons.history, color: vc.onSurface),
        tooltip: 'Transaction history',
        onPressed: () => _showComingSoon(context, 'Transaction history'),
      );
    }

    if (variant == ShellTopBarVariant.campaigns ||
        variant == ShellTopBarVariant.submissions) {
      return IconButton(
        icon: Icon(Icons.tune_rounded, color: vc.onSurface),
        tooltip: 'Filter',
        onPressed: () => _showComingSoon(context, 'Filters'),
      );
    }

    if (variant == ShellTopBarVariant.profile) {
      return IconButton(
        icon: Icon(Icons.more_vert, color: vc.onSurface),
        tooltip: 'More',
        onPressed: () => _showComingSoon(context, 'Profile menu'),
      );
    }

    return const SizedBox.shrink();
  }
}

class _EarningsChip extends StatelessWidget {
  const _EarningsChip({required this.lifetimePaise});

  final int lifetimePaise;

  @override
  Widget build(BuildContext context) {
    final vc = ViralCutColors.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go('/wallet'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: vc.money.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            formatPaise(lifetimePaise),
            style: GoogleFonts.inter(
              color: vc.money,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
