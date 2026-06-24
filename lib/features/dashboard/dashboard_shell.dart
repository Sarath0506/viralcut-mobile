import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/layout/app_spacing.dart';
import '../../theme/viralcut_colors.dart';
import '../submissions/submission_providers.dart';

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

  static const _labels = [
    'Home',
    'Campaigns',
    'Work',
    'Wallet',
    'You',
  ];

  static const _icons = [
    Icons.grid_view_outlined,
    Icons.campaign_outlined,
    Icons.inbox_outlined,
    Icons.account_balance_wallet_outlined,
    Icons.person_outline,
  ];

  static const _selectedIcons = [
    Icons.grid_view,
    Icons.campaign,
    Icons.inbox,
    Icons.account_balance_wallet,
    Icons.person,
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
      body: SafeArea(
        bottom: false,
        child: child,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: AppSpacing.bottomNavHeight,
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_tabs.length, (i) {
              final selected = i == index;
              return _ShellNavIcon(
                icon: selected ? _selectedIcons[i] : _icons[i],
                label: _labels[i],
                selected: selected,
                onTap: () => _onTabSelected(ref, i, context),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _ShellNavIcon extends StatelessWidget {
  const _ShellNavIcon({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final vc = ViralCutColors.of(context);
    final color = selected ? vc.primary : vc.muted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 66,
          height: AppSpacing.bottomNavHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: selected ? 38 : AppSpacing.minTouchTarget,
                height: 30,
                decoration: BoxDecoration(
                  color: selected
                      ? vc.primary.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 22, color: color),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color,
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      height: 1,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
