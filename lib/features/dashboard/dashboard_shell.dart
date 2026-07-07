import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/halchal_colors.dart';
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
  ];

  static const _destinations = [
    (label: 'Dashboard',    icon: Icons.grid_view_outlined,                  selectedIcon: Icons.grid_view_rounded),
    (label: 'Campaigns',    icon: Icons.campaign_outlined,                   selectedIcon: Icons.campaign_rounded),
    (label: 'Submissions',  icon: Icons.near_me_outlined,                    selectedIcon: Icons.near_me_rounded),
    (label: 'Wallet',       icon: Icons.account_balance_wallet_outlined,     selectedIcon: Icons.account_balance_wallet_rounded),
  ];

  int _indexForPath(String path) {
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
    final vc = HalchalColors.of(context);

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
      extendBody: true,
      bottomNavigationBar: _BottomNav(
        selectedIndex: index,
        onTap: (i) => _onTabSelected(ref, i, context),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.selectedIndex, required this.onTap});

  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final vc = HalchalColors.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding + 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: vc.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 30,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: List.generate(
            DashboardShell._destinations.length,
            (i) {
              final d = DashboardShell._destinations[i];
              final selected = i == selectedIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? primary.withValues(alpha: 0.10)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          selected ? d.selectedIcon : d.icon,
                          size: 22,
                          color: selected ? primary : vc.muted,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          d.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: selected ? primary : vc.muted,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
