import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api/api_base_url.dart';
import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/format/money_format.dart';
import '../../core/layout/app_spacing.dart';
import '../../core/layout/list_entrance.dart';
import 'profile_providers.dart';
import '../../theme/viralcut_colors.dart';
import '../../theme/theme_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  String _initialsFor(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to verify your phone again to sign in.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await ref.read(authStateProvider.notifier).logout();
    ref.invalidate(profileMeProvider);
    ref.invalidate(profileDashboardProvider);
    ref.invalidate(profileActiveSubmissionsProvider);

    if (context.mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(profileMeProvider);
    final dash = ref.watch(profileDashboardProvider);
    final activeCount = ref.watch(profileActiveSubmissionsProvider);
    final themeMode = ref.watch(themeModeProvider);
    final vc = ViralCutColors.of(context);
    final primary = Theme.of(context).colorScheme.primary;

    return me.when(
      loading: () => const ScreenLoader(),
      error: (e, _) => _ProfileError(
        error: e,
        onRetry: () => ref.invalidate(profileMeProvider),
        onLogout: () => _logout(context, ref),
      ),
      data: (user) {
        final displayName = user['displayName'] as String? ?? 'Creator';
        final username = user['username'] as String?;
        final phone = user['phone'] as String? ?? '';
        final kycStatus = user['kycStatus'] as String? ?? 'pending';
        final lifetimePaise = dash.valueOrNull?.wallet.lifetimePaise ?? 0;
        final activeSubmissions = activeCount.valueOrNull ?? 0;
        final animationKey =
            '${user['id']}:$lifetimePaise:$activeSubmissions:$kycStatus';

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(profileMeProvider);
            ref.invalidate(profileDashboardProvider);
            ref.invalidate(profileActiveSubmissionsProvider);
          },
          child: ScreenStaggeredColumn(
            animationKey: animationKey,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenHorizontal,
              8,
              AppSpacing.screenHorizontal,
              AppSpacing.lg,
            ),
            children: [
              Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: primary.withValues(alpha: 0.15),
                        child: Text(
                          _initialsFor(displayName),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: primary,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: primary,
                          child: Icon(
                            Icons.edit,
                            size: 14,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    displayName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (username != null && username.isNotEmpty)
                    Text(
                      '@$username',
                      style: GoogleFonts.inter(color: vc.muted),
                    )
                  else if (phone.isNotEmpty)
                    Text(
                      phone,
                      style: GoogleFonts.inter(color: vc.muted),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              dash.when(
                loading: () => const _EarningsCardSkeleton(),
                error: (_, __) => const _EarningsCard(
                  lifetimePaise: 0,
                  error: true,
                ),
                data: (d) => _EarningsCard(
                  lifetimePaise: d.wallet.lifetimePaise,
                ),
              ),
              const SizedBox(height: 12),
              activeCount.when(
                loading: () => const _StatTileSkeleton(),
                error: (_, __) => const SizedBox.shrink(),
                data: (count) => Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        label: 'ACTIVE CLIPS',
                        value: '$count',
                        subtitle: count == 1 ? 'submission' : 'submissions',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SettingsTile(
                icon: Icons.link,
                label: 'Connected accounts',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.verified_user_outlined,
                label: 'KYC status',
                badge: kycStatus.toUpperCase(),
                badgeColor:
                    kycStatus == 'verified' ? vc.moneyBright : vc.warning,
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.account_balance_outlined,
                label: 'Payout methods',
                onTap: () => context.go('/wallet'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Dark mode'),
                value: themeMode == ThemeMode.dark,
                onChanged: (_) =>
                    ref.read(themeModeProvider.notifier).toggle(),
              ),
              const SizedBox(height: 24),
              _LogoutButton(
                onPressed: () => _logout(context, ref),
              ),
            ],
          ),
        );
      },
    );
  }

}

class _ProfileError extends StatelessWidget {
  const _ProfileError({
    required this.error,
    required this.onRetry,
    required this.onLogout,
  });

  final Object error;
  final VoidCallback onRetry;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              error is ApiException
                  ? (error as ApiException).message
                  : '$error',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'API: $kApiBaseUrl\n'
              'On a physical phone use your PC LAN IP:\n'
              'flutter run --dart-define=API_BASE_URL=http://192.168.x.x:3001',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
            const SizedBox(height: 24),
            _LogoutButton(onPressed: onLogout),
          ],
        ),
      ),
    );
  }
}

class _EarningsCard extends StatelessWidget {
  const _EarningsCard({required this.lifetimePaise, this.error = false});

  final int lifetimePaise;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final vc = ViralCutColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: vc.deepSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total earned',
            style: TextStyle(color: vc.onPrimary.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 4),
          Text(
            error ? '—' : formatPaise(lifetimePaise),
            style: TextStyle(
              color: error ? vc.onPrimary.withValues(alpha: 0.7) : vc.moneyBright,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EarningsCardSkeleton extends StatelessWidget {
  const _EarningsCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final vc = ViralCutColors.of(context);
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: vc.deepSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: CircularProgressIndicator(color: vc.onPrimary.withValues(alpha: 0.54)),
    );
  }
}

class _StatTileSkeleton extends StatelessWidget {
  const _StatTileSkeleton();

  @override
  Widget build(BuildContext context) {
    final vc = ViralCutColors.of(context);
    return Container(
      height: 72,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: vc.border),
      ),
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: vc.muted.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.subtitle,
  });

  final String label;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final vc = ViralCutColors.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: vc.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: vc.muted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: vc.onSurface,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: vc.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    this.badge,
    this.badgeColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String? badge;
  final Color? badgeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final vc = ViralCutColors.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: vc.border),
      ),
      child: ListTile(
        leading: Icon(icon, color: vc.muted),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badge != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (badgeColor ?? vc.warning).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: badgeColor ?? vc.warning,
                  ),
                ),
              ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final vc = ViralCutColors.of(context);
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(Icons.logout, color: vc.error),
        label: Text(
          'Log out',
          style: TextStyle(
            color: vc.error,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: vc.infoSurface,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
