import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_provider.dart';
import 'realtime_invalidation.dart';
import 'realtime_providers.dart';

/// Connects Socket.IO when authed and keeps creator-app data in sync.
class RealtimeSync extends ConsumerStatefulWidget {
  const RealtimeSync({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<RealtimeSync> createState() => _RealtimeSyncState();
}

class _RealtimeSyncState extends ConsumerState<RealtimeSync>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ref.listenManual(authStateProvider, (prev, next) {
      if (next == AuthStatus.authed) {
        _connect();
      } else if (next == AuthStatus.unauthed) {
        ref.read(realtimeServiceProvider).disconnect();
      }
    });
    if (ref.read(authStateProvider) == AuthStatus.authed) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _connect());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (ref.read(authStateProvider) != AuthStatus.authed) return;

    ref.read(realtimeServiceProvider).reconnectIfNeeded();
    invalidateAppDataCaches(ref);
  }

  void _onRealtimeEvent(Map<String, dynamic> payload) {
    invalidateAppDataCaches(ref, payload: payload);
  }

  Future<void> _connect() async {
    final token = await ref.read(authStorageProvider).getAccessToken();
    if (token == null || !mounted) return;

    ref.read(realtimeServiceProvider).connect(
          token: token,
          onDeliverableReviewed: _onRealtimeEvent,
          onDeliverableLiveProof: _onRealtimeEvent,
          onDeliverableSubmitted: _onRealtimeEvent,
          onParticipationJoined: _onRealtimeEvent,
          onCampaignCreated: _onRealtimeEvent,
          onCampaignUpdated: _onRealtimeEvent,
          onCampaignPublished: _onRealtimeEvent,
        );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
