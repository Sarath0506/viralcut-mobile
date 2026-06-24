import 'dart:convert';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../api/api_base_url.dart';

typedef RealtimeEventHandler = void Function(Map<String, dynamic> payload);

class RealtimeService {
  io.Socket? _socket;
  String? _token;
  final _joinedCampaignIds = <String>{};

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

    _socket!.on('connect', (_) => _rejoinCampaignRooms());
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
    _joinedCampaignIds.clear();
    _socket?.dispose();
    _socket = null;
  }
}
