import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/halchal_colors.dart';
import '../submissions/submission_providers.dart';
import 'widgets/shell_top_bar.dart';

// Tab switches go through context.go() (see _onTabSelected), which REPLACES
// the current route rather than pushing on top of it — so there's normally
// nothing under e.g. Campaigns for iOS's left-edge "swipe back" gesture to
// pop to, and the drag falls through to iOS's own system gesture and leaves
// the app entirely. This stack is a manual back-history for the tab bar:
// every tab switch pushes the tab being left, and swiping back from the
// left edge pops it and returns to wherever the creator actually came from
// (not just always Dashboard) — see _EdgeSwipeBack below.
final tabHistoryProvider = StateProvider<List<String>>((ref) => []);

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
    if (path.startsWith('/dashboard')) return 0;
    if (path.startsWith('/campaigns')) return 1;
    if (path.startsWith('/submissions')) return 2;
    if (path.startsWith('/wallet')) return 3;
    return -1;
  }

  void _onTabSelected(WidgetRef ref, int index, BuildContext context) {
    final target = _tabs[index];
    final current = GoRouterState.of(context).uri.path;
    if (current != target) {
      ref.read(tabHistoryProvider.notifier).update((h) => [...h, current]);
    }
    if (index == 2) {
      ref.invalidate(participationsProvider('active'));
      ref.invalidate(participationsProvider('completed'));
    }
    context.go(target);
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
          Expanded(child: _EdgeSwipeBack(child: child)),
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

/// Detects a drag starting at the left screen edge and, if it travels far
/// enough right, pops the last entry off [tabHistoryProvider] and navigates
/// there — a manual stand-in for the native "swipe back" gesture, since
/// go_router's context.go() leaves nothing for the real one to pop. A no-op
/// (nothing happens, touch is just consumed) when the history is empty —
/// e.g. Dashboard right after a fresh launch, with nowhere to go back to.
class _EdgeSwipeBack extends ConsumerStatefulWidget {
  const _EdgeSwipeBack({required this.child});

  final Widget child;

  @override
  ConsumerState<_EdgeSwipeBack> createState() => _EdgeSwipeBackState();
}

class _EdgeSwipeBackState extends ConsumerState<_EdgeSwipeBack> {
  // Matches the width iOS's own edge-swipe-back hit zone typically uses.
  static const _edgeZone = 24.0;
  static const _triggerDistance = 60.0;

  bool _startedAtEdge = false;
  double _dragDx = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: (details) {
        _startedAtEdge = details.localPosition.dx <= _edgeZone;
        _dragDx = 0;
      },
      onHorizontalDragUpdate: (details) {
        if (_startedAtEdge) _dragDx += details.delta.dx;
      },
      onHorizontalDragEnd: (details) {
        if (_startedAtEdge && _dragDx > _triggerDistance) {
          final history = ref.read(tabHistoryProvider);
          if (history.isNotEmpty) {
            final previous = history.last;
            ref.read(tabHistoryProvider.notifier).state =
                history.sublist(0, history.length - 1);
            context.go(previous);
          }
        }
        _startedAtEdge = false;
        _dragDx = 0;
      },
      child: widget.child,
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
                        // FittedBox + maxLines: 1 + softWrap: false —
                        // without these, this Text's default wrap
                        // behavior breaks a single word like "Campaigns"
                        // or "Submissions" mid-character (a lone "s"
                        // dropping to its own line) whenever the scaled
                        // text doesn't fit this tab's narrow column width
                        // — seen on narrower Android phones and on any
                        // device with a larger system font-size setting,
                        // since nothing here (or anywhere in the app)
                        // clamps the OS text-scale factor. FittedBox
                        // shrinks the whole label uniformly to fit
                        // instead, so it always reads as one word, just
                        // slightly smaller when space is tight.
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            d.label,
                            maxLines: 1,
                            softWrap: false,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: selected ? primary : vc.muted,
                              height: 1.1,
                            ),
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
