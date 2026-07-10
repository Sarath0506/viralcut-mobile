import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/login_screen.dart';
import '../../features/auth/otp_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/campaigns/campaign_detail_screen.dart';
import '../../features/campaigns/campaigns_screen.dart';
import '../../features/campaigns/leaderboard_screen.dart';
import '../../features/campaigns/submit_work_screen.dart';
import '../../features/dashboard/dashboard_shell.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/profile/connected_accounts_screen.dart';
import '../../features/profile/edit_profile_screen.dart';
import '../../features/profile/kyc_status_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/submissions/participation_detail_screen.dart';
import '../../features/submissions/performance_screen.dart';
import '../../features/submissions/submissions_screen.dart';
import '../../features/support/support_screen.dart';
import '../../features/legal/legal_screen.dart';
import '../../features/wallet/bank_details_screen.dart';
import '../../features/wallet/payout_methods_screen.dart';
import '../../features/wallet/wallet_screen.dart';
import '../../features/wallet/withdraw_screen.dart';
import '../auth/auth_provider.dart';
import '../format/phone_format.dart';
import 'auth_router_refresh.dart';

final _rootKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final refreshListenable = ref.watch(authRouterRefreshProvider);

  final router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final authStatus = ref.read(authStateProvider);
      final path = state.matchedLocation;

      if (authStatus == AuthStatus.unknown) {
        if (path != '/splash') return '/splash';
        return null;
      }

      if (path.startsWith('/otp')) {
        final phone = state.uri.queryParameters['phone'];
        if (!isValidIndiaE164(phone)) return '/login';
      }

      final isAuthed = authStatus == AuthStatus.authed;
      final isPublicRoute = path.startsWith('/splash') ||
          path.startsWith('/onboarding') ||
          path.startsWith('/login') ||
          path.startsWith('/signup') ||
          path.startsWith('/otp');
      if (!isAuthed && !isPublicRoute) return '/splash';
      if (isAuthed && isPublicRoute) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
      GoRoute(path: '/otp', builder: (_, __) => const OtpScreen()),
      ShellRoute(
        builder: (_, __, child) => DashboardShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, __) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/campaigns',
            builder: (_, __) => const CampaignsScreen(),
          ),
          GoRoute(
            path: '/submissions',
            builder: (_, __) => const SubmissionsScreen(),
          ),
          GoRoute(
            path: '/wallet',
            builder: (_, __) => const WalletScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/campaigns/:id',
        builder: (_, state) =>
            CampaignDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/campaigns/:id/submit',
        builder: (_, state) =>
            SubmitWorkScreen(campaignId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/campaigns/:id/leaderboard',
        builder: (_, state) =>
            LeaderboardScreen(campaignId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/leaderboard',
        builder: (_, __) => const LeaderboardScreen(),
      ),
      GoRoute(
        path: '/participations/:id',
        builder: (_, state) =>
            ParticipationDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/submissions/:id',
        redirect: (_, state) => '/participations/${state.pathParameters['id']}',
      ),
      GoRoute(
        path: '/participations/:participationId/performance/:deliverableId',
        builder: (_, state) => PerformanceScreen(
          participationId: state.pathParameters['participationId']!,
          deliverableId: state.pathParameters['deliverableId']!,
        ),
      ),
      GoRoute(path: '/withdraw', builder: (_, __) => const WithdrawScreen()),
      GoRoute(
        path: '/wallet/payout-methods',
        builder: (_, __) => const PayoutMethodsScreen(),
      ),
      GoRoute(
        path: '/wallet/bank-details',
        builder: (_, __) => const BankDetailsScreen(),
      ),
      GoRoute(path: '/legal/terms', builder: (_, __) => const TermsScreen()),
      GoRoute(path: '/legal/privacy', builder: (_, __) => const PrivacyScreen()),
      GoRoute(
        path: '/profile/edit',
        builder: (_, __) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/profile/connected-accounts',
        builder: (_, __) => const ConnectedAccountsScreen(),
      ),
      GoRoute(
        path: '/profile/kyc',
        builder: (_, __) => const KycStatusScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/support',
        builder: (_, __) => const SupportScreen(),
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
