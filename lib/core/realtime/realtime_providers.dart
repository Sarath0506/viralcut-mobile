import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'realtime_service.dart';

final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  final service = RealtimeService();
  ref.onDispose(service.disconnect);
  return service;
});
