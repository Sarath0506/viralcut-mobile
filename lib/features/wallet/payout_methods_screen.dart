import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/widgets/vc_scaffold.dart';
import '../../theme/halchal_colors.dart';
import 'widgets/payout_method_form.dart';
import 'withdraw_screen.dart';

class PayoutMethodsScreen extends ConsumerWidget {
  const PayoutMethodsScreen({super.key});

  Future<void> _setDefault(WidgetRef ref, BuildContext context, String id) async {
    try {
      await ref.read(apiClientProvider).setDefaultPayoutMethod(id);
      ref.invalidate(payoutMethodsProvider);
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _delete(WidgetRef ref, BuildContext context, PayoutMethod m) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove payout method?'),
        content: Text('Remove "${m.label}" (${m.accountMasked})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(apiClientProvider).deletePayoutMethod(m.id);
      ref.invalidate(payoutMethodsProvider);
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final methods = ref.watch(payoutMethodsProvider);
    final vc = HalchalColors.of(context);

    return VcScaffold(
      title: 'Payout Methods',
      showBack: true,
      body: methods.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) {
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(payoutMethodsProvider),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                if (list.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.account_balance_outlined,
                              size: 40, color: vc.muted),
                          const SizedBox(height: 10),
                          Text(
                            'No payout methods yet',
                            style: TextStyle(color: vc.muted, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...list.map(
                    (m) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _PayoutMethodRow(
                        method: m,
                        onSetDefault: () => _setDefault(ref, context, m.id),
                        onDelete: () => _delete(ref, context, m),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const _AddPayoutMethodSheet(),
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add payout method'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PayoutMethodRow extends StatelessWidget {
  const _PayoutMethodRow({
    required this.method,
    required this.onSetDefault,
    required this.onDelete,
  });

  final PayoutMethod method;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final vc = HalchalColors.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: method.isDefault ? vc.primary : vc.border,
          width: method.isDefault ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            method.type == 'upi' ? Icons.phone_android : Icons.account_balance,
            color: method.isDefault ? vc.primary : vc.muted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(method.label,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    if (method.isDefault) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: vc.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('DEFAULT',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: vc.primary)),
                      ),
                    ],
                  ],
                ),
                Text(
                  method.accountHolderName.isNotEmpty
                      ? '${method.accountHolderName} · ${method.accountMasked}'
                      : method.accountMasked,
                  style: TextStyle(fontSize: 12, color: vc.muted),
                ),
                if (method.ifscCode != null && method.ifscCode!.isNotEmpty)
                  Text(
                    method.ifscCode!,
                    style: TextStyle(fontSize: 11, color: vc.muted),
                  ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: vc.muted),
            onSelected: (v) {
              if (v == 'default') onSetDefault();
              if (v == 'delete') onDelete();
            },
            itemBuilder: (context) => [
              if (!method.isDefault)
                const PopupMenuItem(
                    value: 'default', child: Text('Set as default')),
              const PopupMenuItem(value: 'delete', child: Text('Remove')),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddPayoutMethodSheet extends ConsumerWidget {
  const _AddPayoutMethodSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vc = HalchalColors.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        decoration: BoxDecoration(
          color: vc.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: vc.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              PayoutMethodForm(
                title: 'Add payout method',
                onSaved: (_) {
                  ref.invalidate(payoutMethodsProvider);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
