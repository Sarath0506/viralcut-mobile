import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/format/money_format.dart';
import '../../theme/token_colors.dart';

final walletProvider = FutureProvider<WalletData>((ref) async {
  return ref.read(apiClientProvider).fetchWallet();
});

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletProvider);
    final money = Theme.of(context).brightness == Brightness.dark
        ? ViralCutTokenColors.moneyDark
        : ViralCutTokenColors.moneyLight;

    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: wallet.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (w) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(walletProvider),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                formatPaise(w.availablePaise),
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: money,
                ),
              ),
              Text('Available balance'),
              Text(
                '+ ${formatPaise(w.pendingPaise)} pending',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ViralCutTokenColors.warningLight.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'KYC verification coming soon — withdrawals are not blocked in v1.',
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: w.availablePaise > 0
                    ? () => context.push('/withdraw')
                    : null,
                child: const Text('Withdraw to UPI / Bank'),
              ),
              const SizedBox(height: 24),
              Text(
                'Lifetime earned ${formatPaise(w.lifetimePaise)}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
