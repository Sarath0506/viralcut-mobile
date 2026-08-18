import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_provider.dart';
import '../push/push_providers.dart';
import 'realtime_invalidation.dart';
import 'realtime_providers.dart';

/// Connects Socket.IO when authed and keeps creator-app data in sync.
/// Falls back to polling every 30 seconds if WebSocket events are missed.
class RealtimeSync extends ConsumerStatefulWidget {
  const RealtimeSync({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<RealtimeSync> createState() => _RealtimeSyncState();
}

class _RealtimeSyncState extends ConsumerState<RealtimeSync>
    with WidgetsBindingObserver {
  Timer? _pollTimer;
  DateTime? _lastRefresh;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ref.listenManual(authStateProvider, (prev, next) {
      if (next == AuthStatus.authed) {
        // Clear stale data from previous session now that fresh tokens are saved.
        if (prev == AuthStatus.unauthed || prev == AuthStatus.unknown) {
          clearSessionCaches(ref);
        }
        _connect();
        _startPolling();
        ref.read(pushNotificationServiceProvider).init(ref);
      } else if (next == AuthStatus.unauthed) {
        ref.read(realtimeServiceProvider).disconnect();
        _stopPolling();
        // Do NOT invalidate here — widgets are still mounted and would
        // immediately refetch with no token, causing stale 401 errors.
      }
    });
    if (ref.read(authStateProvider) == AuthStatus.authed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _connect();
        _startPolling();
        ref.read(pushNotificationServiceProvider).init(ref);
      });
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (ref.read(authStateProvider) == AuthStatus.authed) {
        _refreshIfStale();
      }
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void dispose() {
    _stopPolling();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _refreshIfStale() {
    final now = DateTime.now();
    if (_lastRefresh != null &&
        now.difference(_lastRefresh!) < const Duration(minutes: 5)) return;
    _lastRefresh = now;
    invalidateAppDataCaches(ref);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (ref.read(authStateProvider) != AuthStatus.authed) return;

    ref.read(realtimeServiceProvider).reconnectIfNeeded();
    _refreshIfStale();
  }

  void _onRealtimeEvent(Map<String, dynamic> payload) {
    invalidateAppDataCaches(ref, payload: payload);
  }

  Future<void> _connect() async {
    String? token;
    try {
      token = await ref
          .read(authStorageProvider)
          .getAccessToken()
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('[RealtimeSync] token read failed: $e');
      token = null;
    }
    if (token == null) {
      debugPrint('[RealtimeSync] no token available — realtime will not connect');
      return;
    }
    if (!mounted) return;

    debugPrint('[RealtimeSync] connecting socket…');
    ref.read(realtimeServiceProvider).connect(
          token: token,
          onDeliverableReviewed: _onRealtimeEvent,
          onDeliverableLiveProof: _onRealtimeEvent,
          onDeliverableSubmitted: _onRealtimeEvent,
          onDeliverablePaid: _onRealtimeEvent,
          onParticipationJoined: _onRealtimeEvent,
          onCampaignCreated: _onRealtimeEvent,
          onCampaignUpdated: _onRealtimeEvent,
          onCampaignPublished: _onRealtimeEvent,
          onCreatorProfileStatsUpdated: _onRealtimeEvent,
          onSupportTicketUpdated: _onRealtimeEvent,
          getFreshToken: () =>
              ref.read(apiClientProvider).refreshAccessToken(),
        );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
