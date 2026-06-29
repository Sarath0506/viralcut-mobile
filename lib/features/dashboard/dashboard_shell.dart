import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/layout/app_spacing.dart';
import '../../theme/viralcut_colors.dart';
import '../submissions/submission_providers.dart';
import 'widgets/shell_top_bar.dart';

class DashboardShell extends ConsumerWidget {
  const DashboardShell({super.key, required this.child});

  final Widget child;

  static const _tabs = [
    '/dashboard',
    '/campaigns',
    '/submissions',
    '/wallet',
    '/profile',
  ];

  static const _destinations = [
    (
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    (
      label: 'Campaigns',
      icon: Icons.campaign_outlined,
      selectedIcon: Icons.campaign,
    ),
    (
      label: 'Submissions',
      icon: Icons.inbox_outlined,
      selectedIcon: Icons.inbox,
    ),
    (
      label: 'Wallet',
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet,
    ),
    (
      label: 'Profile',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
    ),
  ];

  int _indexForPath(String path) {
    if (path.startsWith('/profile')) return 4;
    if (path.startsWith('/wallet')) return 3;
    if (path.startsWith('/submissions')) return 2;
    if (path.startsWith('/campaigns')) return 1;
    return 0;
  }

  void _onTabSelected(WidgetRef ref, int index, BuildContext context) {
    if (index == 2) {
      ref.invalidate(participationsProvider('active'));
      ref.invalidate(participationsProvider('completed'));
    }
    context.go(_tabs[index]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = GoRouterState.of(context).uri.path;
    final index = _indexForPath(path);
    final vc = ViralCutColors.of(context);

    return Scaffold(
      backgroundColor: vc.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SafeArea(
            bottom: false,
            child: ShellTopBar(currentPath: path),
          ),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: vc.surface,
          border: Border(
            top: BorderSide(color: vc.border.withValues(alpha: 0.75)),
          ),
          boxShadow: [
            BoxShadow(
              color: vc.onSurface.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (i) => _onTabSelected(ref, i, context),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
            height: AppSpacing.bottomNavHeight,
            destinations: [
              for (final d in _destinations)
                NavigationDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: d.label,
                  tooltip: d.label,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
