import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/creator_profile/creator_profile_providers.dart';
import '../../../core/layout/app_spacing.dart';
import '../../../theme/viralcut_colors.dart';
import '../../auth/widgets/auth_app_icon.dart';
import '../../profile/profile_providers.dart';
import '../../profile/widgets/profile_switcher_sheet.dart';

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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _ProfileSwitcherChip(),
        const SizedBox(width: 6),
        const _NotificationBell(),
        const SizedBox(width: 4),
        _ProfileAvatar(onTap: () => context.go('/profile')),
      ],
    );
  }
}

class _ProfileSwitcherChip extends ConsumerWidget {
  const _ProfileSwitcherChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vc = ViralCutColors.of(context);
    final profiles = ref.watch(creatorProfilesProvider).valueOrNull ?? [];
    final active = ref.watch(activeCreatorProfileProvider);

    if (profiles.length < 2) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => showProfileSwitcherSheet(context),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 96),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: vc.surfaceVariant,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: vc.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                active?.displayName ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: vc.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.expand_more_rounded, size: 14, color: vc.muted),
          ],
        ),
      ),
    );
  }
}

class _NotificationBell extends ConsumerWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vc = ViralCutColors.of(context);
    final unreadCount = ref.watch(unreadNotificationCountProvider).valueOrNull ?? 0;

    return GestureDetector(
      onTap: () => context.push('/notifications'),
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(Icons.notifications_outlined, color: vc.onSurface, size: 24),
            if (unreadCount > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  decoration: BoxDecoration(
                    color: vc.error,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: vc.background, width: 1.5),
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
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
    final avatarUrl = me.valueOrNull?['avatarUrl'] as String?;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: primary.withValues(alpha: 0.12),
          image: avatarUrl != null
              ? DecorationImage(
                  image: CachedNetworkImageProvider(avatarUrl),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        alignment: Alignment.center,
        child: avatarUrl == null
            ? Text(
                initials,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: primary,
                ),
              )
            : null,
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

