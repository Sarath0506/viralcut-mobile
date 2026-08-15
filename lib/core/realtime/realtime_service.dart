import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../api/api_base_url.dart';

typedef RealtimeEventHandler = void Function(Map<String, dynamic> payload);

/// How often we round-trip a liveness ping while the socket claims to be
/// connected. Some platforms (observed on iOS) can leave a socket reporting
/// `connected == true` while it has silently stopped receiving pushes.
const _heartbeatInterval = Duration(seconds: 20);

/// How long we wait for a heartbeat ack before counting it as missed.
const _heartbeatAckTimeout = Duration(seconds: 8);

/// Consecutive missed heartbeats required before we force a reconnect —
/// avoids reacting to a single transient network blip.
const _maxMissedHeartbeats = 2;

class _Handlers {
  const _Handlers({
    this.onDeliverableReviewed,
    this.onDeliverableLiveProof,
    this.onDeliverableSubmitted,
    this.onDeliverablePaid,
    this.onParticipationJoined,
    this.onCampaignCreated,
    this.onCampaignUpdated,
    this.onCampaignPublished,
    this.onCreatorProfileStatsUpdated,
    this.onSupportTicketUpdated,
  });

  final RealtimeEventHandler? onDeliverableReviewed;
  final RealtimeEventHandler? onDeliverableLiveProof;
  final RealtimeEventHandler? onDeliverableSubmitted;
  final RealtimeEventHandler? onDeliverablePaid;
  final RealtimeEventHandler? onParticipationJoined;
  final RealtimeEventHandler? onCampaignCreated;
  final RealtimeEventHandler? onCampaignUpdated;
  final RealtimeEventHandler? onCampaignPublished;
  final RealtimeEventHandler? onCreatorProfileStatsUpdated;
  final RealtimeEventHandler? onSupportTicketUpdated;
}

class RealtimeService {
  io.Socket? _socket;
  String? _token;
  _Handlers? _handlers;
  Future<String?> Function()? _getFreshToken;
  bool _refreshingToken = false;
  final _joinedCampaignIds = <String>{};
  Timer? _heartbeatTimer;
  int _missedHeartbeats = 0;

  bool get isConnected => _socket?.connected ?? false;

  void connect({
    required String token,
    RealtimeEventHandler? onDeliverableReviewed,
    RealtimeEventHandler? onDeliverableLiveProof,
    RealtimeEventHandler? onDeliverableSubmitted,
    RealtimeEventHandler? onDeliverablePaid,
    RealtimeEventHandler? onParticipationJoined,
    RealtimeEventHandler? onCampaignCreated,
    RealtimeEventHandler? onCampaignUpdated,
    RealtimeEventHandler? onCampaignPublished,
    RealtimeEventHandler? onCreatorProfileStatsUpdated,
    RealtimeEventHandler? onSupportTicketUpdated,
    // Called when the server rejects the current token so we can fetch a
    // live one — the socket has no interceptor like REST calls do, so
    // without this it just keeps retrying with the same rejected token.
    Future<String?> Function()? getFreshToken,
  }) {
    _handlers = _Handlers(
      onDeliverableReviewed: onDeliverableReviewed,
      onDeliverableLiveProof: onDeliverableLiveProof,
      onDeliverableSubmitted: onDeliverableSubmitted,
      onDeliverablePaid: onDeliverablePaid,
      onParticipationJoined: onParticipationJoined,
      onCampaignCreated: onCampaignCreated,
      onCampaignUpdated: onCampaignUpdated,
      onCampaignPublished: onCampaignPublished,
      onCreatorProfileStatsUpdated: onCreatorProfileStatsUpdated,
      onSupportTicketUpdated: onSupportTicketUpdated,
    );
    _getFreshToken = getFreshToken;
    _openSocket(token);
  }

  void _openSocket(String token) {
    _token = token;
    disconnect();

    _socket = io.io(
      '$kApiBaseUrl/realtime',
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(12)
          .setReconnectionDelay(1500)
          .setAuth({'token': token})
          .build(),
    );

    final handlers = _handlers;
    void listen(String event, RealtimeEventHandler? handler) {
      if (handler == null) return;
      _socket!.on(event, (data) {
        final payload = _parsePayload(data);
        if (payload != null) {
          handler(payload);
        }
      });
    }

    listen('deliverable:reviewed', handlers?.onDeliverableReviewed);
    listen('deliverable:live_proof', handlers?.onDeliverableLiveProof);
    listen('deliverable:submitted', handlers?.onDeliverableSubmitted);
    listen('deliverable:paid', handlers?.onDeliverablePaid);
    listen('participation:joined', handlers?.onParticipationJoined);
    listen('campaign:created', handlers?.onCampaignCreated);
    listen('campaign:updated', handlers?.onCampaignUpdated);
    listen('campaign:published', handlers?.onCampaignPublished);
    listen('creatorProfile:statsUpdated', handlers?.onCreatorProfileStatsUpdated);
    listen('supportTicket:updated', handlers?.onSupportTicketUpdated);

    _socket!.on('connect', (_) {
      debugPrint('[RealtimeService] connected: ${_socket!.id}');
      _missedHeartbeats = 0;
      _rejoinCampaignRooms();
      _startHeartbeat();
    });
    _socket!.on('connect_error', (err) {
      debugPrint('[RealtimeService] connect_error: $err');
      _reconnectWithFreshToken();
    });
    _socket!.on('disconnect', (reason) {
      debugPrint('[RealtimeService] disconnected: $reason');
      // "io server disconnect" means the server actively rejected us
      // (expired/invalid token) — socket.io won't auto-reconnect after
      // this reason on its own, and even if it did it would keep sending
      // the same rejected token. Everything else (network drop, etc.) is
      // already covered by enableReconnection().
      if (reason == 'io server disconnect') {
        _reconnectWithFreshToken();
      }
    });
    _socket!.on('reconnect_attempt', (attempt) {
      debugPrint('[RealtimeService] reconnect_attempt #$attempt');
    });
  }

  Future<void> _reconnectWithFreshToken() async {
    final getFreshToken = _getFreshToken;
    if (getFreshToken == null || _refreshingToken) return;

    _refreshingToken = true;
    try {
      final freshToken = await getFreshToken();
      if (freshToken == null || freshToken == _token) {
        debugPrint('[RealtimeService] no fresher token available, giving up');
        return;
      }
      debugPrint('[RealtimeService] reconnecting with refreshed token');
      _openSocket(freshToken);
    } finally {
      _refreshingToken = false;
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) => _sendHeartbeat());
  }

  void _sendHeartbeat() {
    final socket = _socket;
    if (socket == null || !socket.connected) return;

    var acked = false;
    socket.emitWithAck('ping', null, ack: (_) {
      acked = true;
      _missedHeartbeats = 0;
    });

    Timer(_heartbeatAckTimeout, () {
      if (acked) return;
      _missedHeartbeats++;
      debugPrint('[RealtimeService] missed heartbeat ($_missedHeartbeats/$_maxMissedHeartbeats)');
      if (_missedHeartbeats < _maxMissedHeartbeats) return;

      // Socket reports connected but stopped responding — force a real
      // reconnect rather than trusting the stale `connected` flag.
      debugPrint('[RealtimeService] forcing reconnect after missed heartbeats');
      _missedHeartbeats = 0;
      _socket?.disconnect();
      _socket?.connect();
    });
  }

  void joinCampaignRoom(String campaignId) {
    if (campaignId.isEmpty) return;
    _joinedCampaignIds.add(campaignId);
    _socket?.emit('campaign:join', {'campaignId': campaignId});
  }

  void leaveCampaignRoom(String campaignId) {
    if (campaignId.isEmpty) return;
    _joinedCampaignIds.remove(campaignId);
    _socket?.emit('campaign:leave', {'campaignId': campaignId});
  }

  void _rejoinCampaignRooms() {
    for (final campaignId in _joinedCampaignIds) {
      _socket?.emit('campaign:join', {'campaignId': campaignId});
    }
  }

  /// Called on app resume — the most likely moment for the token to have
  /// gone stale while backgrounded, so this always tries for a fresh one
  /// rather than reusing whatever the socket last connected with.
  Future<void> reconnectIfNeeded() async {
    if (_token == null) return;
    if (_socket != null && _socket!.connected) return;

    final getFreshToken = _getFreshToken;
    if (getFreshToken != null) {
      final freshToken = await getFreshToken();
      if (freshToken != null) {
        _openSocket(freshToken);
        return;
      }
    }
    _socket?.connect();
  }

  Map<String, dynamic>? _parsePayload(dynamic data) {
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  void disconnect() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _joinedCampaignIds.clear();
    _socket?.dispose();
    _socket = null;
  }
}
