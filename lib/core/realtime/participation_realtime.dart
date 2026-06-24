import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bumped on each realtime event so watched providers refetch automatically.
final participationRealtimeTickProvider = StateProvider<int>((ref) => 0);

/// Watch inside [FutureProvider] bodies to refetch when realtime events arrive.
void watchAppRealtimeTick(Ref ref) {
  ref.watch(participationRealtimeTickProvider);
}
