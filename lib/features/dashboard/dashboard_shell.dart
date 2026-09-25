import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodChannel;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/halchal_colors.dart';
import '../submissions/submission_providers.dart';
import 'widgets/shell_top_bar.dart';

// Tab switches go through context.go() (see _onTabSelected), which REPLACES
// the current route rather than pushing on top of it — so there's normally
// nothing under e.g. Campaigns for a "swipe back" gesture to pop to, and
// the drag falls through to the OS's own system gesture and leaves the app
// entirely. This stack is a manual back-history for the tab bar: every tab
// switch pushes the tab being left, and swiping back returns to wherever
// the creator actually came from (not just always Dashboard) — see the
// PopScope wrapping DashboardShell's Scaffold below.
//
// This used to be driven by a custom GestureDetector watching raw edge
// touches (_EdgeSwipeBack). That approach fundamentally couldn't win:
// HitTestBehavior only controls how *Flutter* sees a touch — Android's own
// gesture recognizer runs outside the Flutter engine entirely and acts on
// the SAME raw touch in parallel, so a correctly-firing in-app handler and
// the OS's own edge-swipe-back/home gesture both fired on every swipe.
// Confirmed live on a real Samsung device (dumpsys + adb logcat): our
// handler's navigation ran successfully, but Android — seeing no back
// stack to pop inside this route since it has no actual Navigator entries
// under it — independently finished/backgrounded the Activity on the same
// touch, which is FlutterActivity's default behavior for an unhandled
// system back gesture. `View.setSystemGestureExclusionRects` doesn't fix
// this either: it only ever covers the OS's "back" category specifically,
// never the home/recents-switching gesture (permanently unexcludable by
// design) or Samsung's own proprietary Edge Panel/Pay edge shortcuts.
//
// PopScope + Android's official OnBackInvokedCallback (already enabled —
// see AndroidManifest.xml's android:enableOnBackInvokedCallback) sidesteps
// all of this: instead of racing the OS for ownership of a raw touch, it's
// the SAME explicit system channel FlutterActivity already registers a
// callback on for every edge-swipe-back gesture. canPop: false there tells
// Android directly not to run its default action (finish the Activity) so
// there's nothing left to race against.
final tabHistoryProvider = StateProvider<List<String>>((ref) => []);

// A dedicated channel to MainActivity.kt, separate from Flutter's own
// internal `flutter/platform` channel — see the long comment on
// DashboardShell.build for why sharing that one doesn't work here.
// Android-only: no iOS side registers a handler for it (iOS doesn't have
// the OS-level edge-gesture-arena conflict this works around — Apple's
// swipe-back only acts within Flutter's own Navigator, it doesn't run a
// separate, parallel system recognizer against Flutter's PopScope the way
// Android's predictive back does), so calling it unguarded there throws
// MissingPluginException on every tab switch.
const _backGestureChannel = MethodChannel('com.halchal.app/back_gesture');
final _isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

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
    final history = ref.watch(tabHistoryProvider);

    // PopScope's canPop below *should* be enough on its own — Flutter is
    // supposed to derive ModalRoute.popDisposition from it and relay that to
    // Android via the SystemNavigator.setFrameworkHandlesBack platform
    // channel call, which is what actually makes native register its
    // OnBackInvokedCallback at a priority that can pre-empt the OS's own
    // edge-swipe-back/home gesture. Confirmed live (raw adb logcat) that
    // this relay silently doesn't happen for a ShellRoute branch reached via
    // context.go() (which replaces the stack instead of pushing, so this
    // route is always Navigator's lone/"first" entry): canPop was correctly
    // false and onPopInvokedWithResult never fired, and Android's own
    // ShellBackPreview logged choosing mType=TYPE_RETURN_TO_HOME — its
    // default for "nothing registered wants this" — for a swipe that should
    // have been ours to intercept.
    //
    // Calling SystemNavigator.setFrameworkHandlesBack ourselves *also*
    // wasn't enough on its own — confirmed live that Flutter's own internal
    // mechanism keeps calling the SAME method with its own (wrong, for this
    // route) determination, on its own schedule, and whichever call landed
    // last won — so our explicit "true" kept getting silently clobbered by
    // Flutter's automatic "false" straight after. _backGestureChannel is a
    // separate channel Flutter's internals never touch, so MainActivity.kt
    // can OR our explicit intent together with Flutter's own signal instead
    // of racing it — our intent can only turn interception ON that
    // Flutter's automatic calls would've turned off, never the reverse.
    if (_isAndroid) {
      _backGestureChannel.invokeMethod('setInterceptEnabled', history.isNotEmpty);
      ref.listen<List<String>>(tabHistoryProvider, (previous, next) {
        _backGestureChannel.invokeMethod('setInterceptEnabled', next.isNotEmpty);
      });
    }

    return PopScope(
      // History empty (e.g. Dashboard right after a fresh launch, nothing
      // to go back to) -> canPop: true, _backGestureChannel above already
      // told native not to intercept, so the system's default back action
      // (exit to home) happens normally. History non-empty -> canPop: false
      // plus native's OR'd-in intercept together stop Android from running
      // its default action, so onPopInvokedWithResult's navigation below is
      // the only thing that runs on the gesture, instead of racing it.
      canPop: history.isEmpty,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final current = ref.read(tabHistoryProvider);
        if (current.isEmpty) return;
        final previous = current.last;
        ref.read(tabHistoryProvider.notifier).state =
            current.sublist(0, current.length - 1);
        context.go(previous);
      },
      child: Scaffold(
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
