import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/participation/participation_models.dart';
import '../../core/realtime/participation_realtime.dart';

final walletProvider = FutureProvider<WalletData>((ref) async {
  watchAppRealtimeTick(ref);
  return ref.read(apiClientProvider).fetchWallet();
});

final walletTransactionsProvider = FutureProvider<List<TransactionItem>>((ref) async {
  watchAppRealtimeTick(ref);
  return ref.read(apiClientProvider).fetchTransactions();
});

final clipsUnderReviewCountProvider = FutureProvider<int>((ref) async {
  watchAppRealtimeTick(ref);
  final items = await ref.read(apiClientProvider).fetchParticipations(tab: 'active');
  return items.where((p) => p.summary == 'in_review').length;
});
