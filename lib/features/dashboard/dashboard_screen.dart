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
import '../../theme/halchal_colors.dart';
import 'widgets/dashboard_earnings_card.dart';
import 'widgets/trending_campaigns_carousel.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardProvider);
    final displayName = ref.watch(profileMeProvider).maybeWhen(
          data: (user) => user['displayName'] as String?,
          orElse: () => null,
        );

    return state.when(
      skipLoadingOnRefresh: true,
      loading: () => const ScreenLoader(),
      error: (e, _) => _DashboardError(
        error: e,
        onRetry: () => ref.invalidate(dashboardProvider),
      ),
      data: (data) {
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(dashboardProvider),
          child: ScreenStaggeredColumn(
            animationKey: 'dashboard',
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenHorizontal,
              AppSpacing.sm,
              AppSpacing.screenHorizontal,
              AppSpacing.floatingNavBottom(context),
            ),
            children: [
              _DashboardHeader(displayName: displayName),
              const SizedBox(height: 16),
              DashboardEarningsCard(
                wallet: data.wallet,
                clipsUnderReview: data.clipsUnderReview,
                onWithdraw: () => context.go('/wallet'),
              ),
              const SizedBox(height: 12),
              _OverallLeaderboardLink(
                onTap: () => context.push('/leaderboard'),
              ),
              const SizedBox(height: 14),
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
    final vc = HalchalColors.of(context);
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
              const TextSpan(text: 'Post clips.\n'),
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

class _OverallLeaderboardLink extends StatelessWidget {
  const _OverallLeaderboardLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final vc = HalchalColors.of(context);

    return Material(
      color: vc.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: vc.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.emoji_events_outlined, color: vc.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overall leaderboard',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: vc.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'See how you rank across all campaigns',
                      style: GoogleFonts.inter(fontSize: 11, color: vc.muted),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: vc.muted),
            ],
          ),
        ),
      ),
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
