import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api/api_base_url.dart';
import '../../core/api/api_client.dart';
import '../../core/format/money_format.dart';
import '../../core/layout/app_spacing.dart';
import 'dashboard_providers.dart';
import '../../theme/viralcut_colors.dart';
import '../auth/widgets/auth_app_icon.dart';
import 'widgets/dashboard_earnings_card.dart';
import 'widgets/social_connect_section.dart';
import 'widgets/trending_campaigns_carousel.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  void _showSocialLinkSnackBar(BuildContext context, String platform) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$platform linking coming soon')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardProvider);

    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _DashboardError(
        error: e,
        onRetry: () => ref.invalidate(dashboardProvider),
        onProfile: () => context.go('/profile'),
      ),
      data: (data) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(dashboardProvider),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            AppSpacing.sm,
            AppSpacing.screenHorizontal,
            AppSpacing.xl,
          ),
          children: <Widget>[
            _DashboardTopBar(
              wallet: data.wallet,
              onProfileTap: () => context.go('/profile'),
            ),
            const SizedBox(height: 20),
            const _DashboardHeader(),
            const SizedBox(height: 20),
            DashboardEarningsCard(
              wallet: data.wallet,
              clipsUnderReview: data.clipsUnderReview,
              onWithdraw: () => context.go('/wallet'),
            ),
            const SizedBox(height: 20),
            SocialConnectSection(
              links: data.socialLinks,
              onInstagramTap: () =>
                  _showSocialLinkSnackBar(context, 'Instagram'),
              onYouTubeTap: () => _showSocialLinkSnackBar(context, 'YouTube'),
            ),
            const SizedBox(height: 20),
            TrendingCampaignsCarousel(
              campaigns: data.trending,
              onCampaignTap: (c) => context.push('/campaigns/${c.id}'),
              onViewAll: () => context.go('/campaigns'),
            ),
          ].animate(interval: 50.ms).fade(duration: 400.ms, curve: Curves.easeOut).slideY(begin: 0.05, duration: 400.ms, curve: Curves.easeOut),
        ),
      ),
    );
  }
}

class _DashboardTopBar extends StatelessWidget {
  const _DashboardTopBar({required this.wallet, required this.onProfileTap});

  final WalletData wallet;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    final vc = ViralCutColors.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const AuthAppIcon.header(),
            const SizedBox(width: 8),
            Text(
              'Halchal',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: vc.onSurface,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: vc.money.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                formatPaise(wallet.lifetimePaise),
                style: GoogleFonts.inter(
                  color: vc.money,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: onProfileTap,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: vc.border),
                ),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: vc.primary.withValues(alpha: 0.1),
                  child: Icon(Icons.person, color: vc.primary, size: 20),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    final vc = ViralCutColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hey Pragnatej',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: vc.muted,
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
              color: vc.onSurface,
              height: 1.16,
            ),
            children: [
              const TextSpan(text: 'Post clips. '),
              TextSpan(
                text: 'Get paid.',
                style: TextStyle(color: vc.primary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({
    required this.error,
    required this.onRetry,
    required this.onProfile,
  });

  final Object error;
  final VoidCallback onRetry;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$error', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(
              'Cannot reach API at $kApiBaseUrl',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Physical phone: use your PC IP, not 10.0.2.2.\n'
              'flutter run --dart-define=API_BASE_URL=http://192.168.x.x:3001',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
            TextButton(
              onPressed: onProfile,
              child: const Text('Go to You / Log out'),
            ),
          ],
        ),
      ),
    );
  }
}
