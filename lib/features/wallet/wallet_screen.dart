import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format/money_format.dart';
import '../../core/layout/app_spacing.dart';
import '../../core/layout/list_entrance.dart';
import 'wallet_providers.dart';
import '../../theme/viralcut_colors.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletProvider);
    final vc = ViralCutColors.of(context);

    return wallet.when(
      loading: () => const ScreenLoader(),
      error: (e, _) => Center(child: Text('$e')),
      data: (w) {
        final animationKey = [
          w.availablePaise,
          w.pendingPaise,
          w.lifetimePaise,
        ].join('|');

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(walletProvider),
          child: ScreenStaggeredColumn(
            animationKey: animationKey,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
            children: [
              Text(
                formatPaise(w.availablePaise),
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: vc.money,
                ),
              ),
              const Text('Available balance'),
              Text(
                '+ ${formatPaise(w.pendingPaise)} pending',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: vc.warning.withValues(alpha: 0.12),
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
        );
      },
    );
  }
}
