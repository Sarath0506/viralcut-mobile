import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/format/money_format.dart';
import '../../../core/layout/app_spacing.dart';
import '../../../theme/viralcut_colors.dart';
import '../dashboard_providers.dart';
import '../../auth/widgets/auth_app_icon.dart';
import '../../profile/profile_providers.dart';

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
    final primary = Theme.of(context).colorScheme.primary;

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
            color: variant == ShellTopBarVariant.home ? primary : vc.onSurface,
          ),
        ),
      ],
    );
  }
}

class _Trailing extends ConsumerWidget {
  const _Trailing({required this.variant});

  final ShellTopBarVariant variant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          const SizedBox(width: 4),
          _ProfileAvatar(onTap: () => context.go('/profile')),
        ],
      );
    }

    return _ProfileAvatar(onTap: () => context.go('/profile'));
  }
}

class _ProfileAvatar extends ConsumerWidget {
  const _ProfileAvatar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = Theme.of(context).colorScheme.primary;
    final me = ref.watch(profileMeProvider);

    final initials = me.valueOrNull != null
        ? _initials(me.valueOrNull!['displayName'] as String? ?? '')
        : '?';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: primary.withValues(alpha: 0.12),
        ),
        alignment: Alignment.center,
        child: Text(
          initials,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: primary,
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
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
            border: Border.all(color: vc.money.withValues(alpha: 0.25)),
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
