import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api/api_base_url.dart';
import '../../core/layout/app_spacing.dart';
import '../../core/layout/list_entrance.dart';
import 'dashboard_providers.dart';
import '../../features/profile/profile_providers.dart';
import '../../core/campaign/campaign_schedule_label.dart';
import '../../theme/viralcut_colors.dart';
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
    final displayName = ref.watch(profileMeProvider).maybeWhen(
          data: (user) => user['displayName'] as String?,
          orElse: () => null,
        );

    return state.when(
      loading: () => const ScreenLoader(),
      error: (e, _) => _DashboardError(
        error: e,
        onRetry: () => ref.invalidate(dashboardProvider),
      ),
      data: (data) {
        final animationKey = [
          data.wallet.availablePaise,
          data.wallet.pendingPaise,
          data.clipsUnderReview,
          ...data.trending.map((c) => c.id),
        ].join('|');

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(dashboardProvider),
          child: ScreenStaggeredColumn(
            animationKey: animationKey,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenHorizontal,
              AppSpacing.sm,
              AppSpacing.screenHorizontal,
              AppSpacing.floatingNavBottom(context),
            ),
            children: [
              _DashboardHeader(displayName: displayName),
              const SizedBox(height: 20),
              DashboardEarningsCard(
                wallet: data.wallet,
                clipsUnderReview: data.clipsUnderReview,
                onWithdraw: () => context.go('/wallet'),
              ),
              const SizedBox(height: 16),
              SocialConnectSection(
                links: data.socialLinks,
                onInstagramTap: () =>
                    _showSocialLinkSnackBar(context, 'Instagram'),
                onYouTubeTap: () =>
                    _showSocialLinkSnackBar(context, 'YouTube'),
                onXTap: () =>
                    _showSocialLinkSnackBar(context, 'X'),
              ),
              const SizedBox(height: 16),
              TrendingCampaignsCarousel(
                campaigns: data.trending,
                onCampaignTap: (c) => context.push('/campaigns/${c.id}'),
                onViewAll: () => context.go('/campaigns'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({this.displayName});

  final String? displayName;

  @override
  Widget build(BuildContext context) {
    final vc = ViralCutColors.of(context);
    final name = dashboardGreetingName(displayName);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hey $name 👋',
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
  });

  final Object error;
  final VoidCallback onRetry;

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
          ],
        ),
      ),
    );
  }
}
