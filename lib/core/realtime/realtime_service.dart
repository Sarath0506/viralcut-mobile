import 'dart:async';
import 'dart:convert';

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

class RealtimeService {
  io.Socket? _socket;
  String? _token;
  final _joinedCampaignIds = <String>{};
  Timer? _heartbeatTimer;
  int _missedHeartbeats = 0;

  bool get isConnected => _socket?.connected ?? false;

  void connect({
    required String token,
    RealtimeEventHandler? onDeliverableReviewed,
    RealtimeEventHandler? onDeliverableLiveProof,
    RealtimeEventHandler? onDeliverableSubmitted,
    RealtimeEventHandler? onParticipationJoined,
    RealtimeEventHandler? onCampaignCreated,
    RealtimeEventHandler? onCampaignUpdated,
    RealtimeEventHandler? onCampaignPublished,
    RealtimeEventHandler? onCreatorProfileStatsUpdated,
  }) {
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

    void listen(String event, RealtimeEventHandler? handler) {
      if (handler == null) return;
      _socket!.on(event, (data) {
        final payload = _parsePayload(data);
        if (payload != null) {
          handler(payload);
        }
      });
    }

    listen('deliverable:reviewed', onDeliverableReviewed);
    listen('deliverable:live_proof', onDeliverableLiveProof);
    listen('deliverable:submitted', onDeliverableSubmitted);
    listen('participation:joined', onParticipationJoined);
    listen('campaign:created', onCampaignCreated);
    listen('campaign:updated', onCampaignUpdated);
    listen('campaign:published', onCampaignPublished);
    listen('creatorProfile:statsUpdated', onCreatorProfileStatsUpdated);

    _socket!.on('connect', (_) {
      _missedHeartbeats = 0;
      _rejoinCampaignRooms();
      _startHeartbeat();
    });
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
      if (_missedHeartbeats < _maxMissedHeartbeats) return;

      // Socket reports connected but stopped responding — force a real
      // reconnect rather than trusting the stale `connected` flag.
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

  void reconnectIfNeeded() {
    final token = _token;
    if (token == null) return;
    if (_socket == null || !_socket!.connected) {
      _socket?.connect();
    }
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
