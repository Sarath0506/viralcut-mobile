import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/format/money_format.dart';
import '../../core/widgets/vc_scaffold.dart';

final payoutMethodsProvider = FutureProvider<List<PayoutMethod>>((ref) async {
  return ref.read(apiClientProvider).fetchPayoutMethods();
});

class WithdrawScreen extends ConsumerStatefulWidget {
  const WithdrawScreen({super.key});

  @override
  ConsumerState<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends ConsumerState<WithdrawScreen> {
  final _amountController = TextEditingController();
  String? _methodId;
  bool _loading = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final methods = ref.watch(payoutMethodsProvider);

    return VcScaffold(
      title: 'Withdraw',
      showBack: true,
      body: methods.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) {
          if (list.isNotEmpty && _methodId == null) {
            _methodId = list.first.id;
          }
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount (₹)',
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Platform fee 1.5% applies'),
                const SizedBox(height: 16),
                RadioGroup<String>(
                  groupValue: _methodId,
                  onChanged: (v) => setState(() => _methodId = v),
                  child: Column(
                    children: [
                      for (final m in list)
                        RadioListTile<String>(
                          title: Text(m.label),
                          subtitle: Text(m.accountMasked),
                          value: m.id,
                        ),
                    ],
                  ),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _loading || _methodId == null
                      ? null
                      : () async {
                          final rupees =
                              int.tryParse(_amountController.text) ?? 0;
                          if (rupees <= 0) return;
                          setState(() => _loading = true);
                          try {
                            final result = await ref
                                .read(apiClientProvider)
                                .createWithdrawal(
                                  amountPaise: rupees * 100,
                                  payoutMethodId: _methodId!,
                                  idempotencyKey:
                                      'wd-${DateTime.now().millisecondsSinceEpoch}',
                                );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'You receive ${formatPaise(result.netPaise)} (fee ${formatPaise(result.feePaise)})',
                                  ),
                                ),
                              );
                              context.pop();
                            }
                          } on ApiException catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.message)),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _loading = false);
                          }
                        },
                  child: Text(_loading ? 'Processing…' : 'Withdraw now'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
