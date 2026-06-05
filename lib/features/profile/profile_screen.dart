import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api/api_base_url.dart';
import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/format/money_format.dart';
import '../../theme/token_colors.dart';
import '../../theme/theme_provider.dart';

final profileMeProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.read(apiClientProvider).fetchMe();
});

final profileDashboardProvider =
    FutureProvider<CreatorDashboard>((ref) async {
  return ref.read(apiClientProvider).fetchDashboard();
});

final profileActiveSubmissionsProvider = FutureProvider<int>((ref) async {
  final items =
      await ref.read(apiClientProvider).fetchSubmissions(tab: 'active');
  return items.length;
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

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
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: ViralCutTokenColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  const SizedBox(width: 48),
                  Expanded(
                    child: Text(
                      'Profile',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: primary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            Expanded(
              child: me.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => _ProfileError(
                  error: e,
                  onRetry: () => ref.invalidate(profileMeProvider),
                  onLogout: () => _logout(context, ref),
                ),
                data: (user) {
                  final displayName =
                      user['displayName'] as String? ?? 'Creator';
                  final username = user['username'] as String?;
                  final phone = user['phone'] as String? ?? '';
                  final kycStatus =
                      user['kycStatus'] as String? ?? 'pending';
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(profileMeProvider);
                      ref.invalidate(profileDashboardProvider);
                      ref.invalidate(profileActiveSubmissionsProvider);
                    },
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      children: [
                        Column(
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                CircleAvatar(
                                  radius: 44,
                                  backgroundColor:
                                      primary.withValues(alpha: 0.15),
                                  child: Icon(Icons.person,
                                      size: 44, color: primary),
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: CircleAvatar(
                                    radius: 14,
                                    backgroundColor: primary,
                                    child: const Icon(Icons.edit,
                                        size: 14, color: Colors.white),
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
                                style: GoogleFonts.inter(
                                  color: ViralCutTokenColors.mutedLight,
                                ),
                              )
                            else if (phone.isNotEmpty)
                              Text(
                                phone,
                                style: GoogleFonts.inter(
                                  color: ViralCutTokenColors.mutedLight,
                                ),
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
                          loading: () => const SizedBox(
                            height: 72,
                            child: Center(
                                child: CircularProgressIndicator()),
                          ),
                          error: (_, __) => const SizedBox.shrink(),
                          data: (count) => Row(
                            children: [
                              Expanded(
                                child: _StatTile(
                                  label: 'ACTIVE CLIPS',
                                  value: '$count',
                                  subtitle: count == 1
                                      ? 'submission'
                                      : 'submissions',
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
                          badgeColor: kycStatus == 'verified'
                              ? ViralCutTokenColors.moneyBrightLight
                              : ViralCutTokenColors.warningLight,
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
              ),
            ),
          ],
        ),
      ),
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
            Text('$error', textAlign: TextAlign.center),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ViralCutTokenColors.deepSurfaceLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total earned',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 4),
          Text(
            error ? '—' : formatPaise(lifetimePaise),
            style: TextStyle(
              color: error
                  ? Colors.white70
                  : ViralCutTokenColors.moneyBrightLight,
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
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: ViralCutTokenColors.deepSurfaceLight,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(color: Colors.white54),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ViralCutTokenColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: ViralCutTokenColors.mutedLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: ViralCutTokenColors.mutedLight,
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
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: ViralCutTokenColors.borderLight),
      ),
      child: ListTile(
        leading: Icon(icon, color: ViralCutTokenColors.mutedLight),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badge != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (badgeColor ?? ViralCutTokenColors.warningLight)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: badgeColor ?? ViralCutTokenColors.warningLight,
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
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.logout, color: ViralCutTokenColors.errorLight),
        label: const Text(
          'Log out',
          style: TextStyle(
            color: ViralCutTokenColors.errorLight,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: const Color(0xFFEFF6FF),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
