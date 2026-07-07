import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/format/money_format.dart';
import '../../core/layout/app_spacing.dart';
import '../../core/widgets/vc_scaffold.dart';
import '../../theme/halchal_colors.dart';
import 'wallet_providers.dart';
import 'widgets/payout_method_form.dart';

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

  int get _amountPaise => (int.tryParse(_amountController.text) ?? 0) * 100;
  int get _feePaise => (_amountPaise * 150 ~/ 10000);
  int get _netPaise => _amountPaise - _feePaise;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _addAmount(int rupees) {
    final current = int.tryParse(_amountController.text) ?? 0;
    _amountController.text = '${current + rupees}';
    setState(() {});
  }

  Future<void> _submit(List<PayoutMethod> methods) async {
    if (_methodId == null || _amountPaise <= 0) return;
    setState(() => _loading = true);
    try {
      final result = await ref.read(apiClientProvider).createWithdrawal(
            amountPaise: _amountPaise,
            payoutMethodId: _methodId!,
            idempotencyKey: 'wd-${DateTime.now().millisecondsSinceEpoch}',
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You receive ${formatPaise(result.netPaise)} (fee ${formatPaise(result.feePaise)})',
          ),
        ),
      );
      ref.invalidate(walletProvider);
      context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletProvider);
    final methods = ref.watch(payoutMethodsProvider);
    final vc = HalchalColors.of(context);
    final primary = Theme.of(context).colorScheme.primary;

    return VcScaffold(
      title: 'Withdraw',
      showBack: true,
      body: methods.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) {
          if (list.isNotEmpty && _methodId == null) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => setState(() => _methodId = list.first.id),
            );
          }

          final availablePaise = wallet.valueOrNull?.availablePaise ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenHorizontal,
              AppSpacing.sm,
              AppSpacing.screenHorizontal,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Balance card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: vc.deepSurface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available balance',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white60,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        formatPaise(availablePaise),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: vc.moneyBright,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Amount input
                Text(
                  'ENTER AMOUNT',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: vc.muted,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: vc.onSurface,
                  ),
                  decoration: InputDecoration(
                    prefixText: '₹ ',
                    prefixStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: vc.muted,
                    ),
                    hintText: '0',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: vc.border,
                    ),
                    filled: true,
                    fillColor: vc.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: vc.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: vc.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Quick-add chips
                Wrap(
                  spacing: 8,
                  children: [1000, 5000, 10000, 20000].map((r) {
                    return ActionChip(
                      label: Text('+₹${r ~/ 1}'),
                      onPressed: () => _addAmount(r),
                      backgroundColor: vc.surface,
                      side: BorderSide(color: vc.border),
                      labelStyle: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: vc.onSurface,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                if (list.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'WITHDRAW TO',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: vc.muted,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context
                            .push('/wallet/payout-methods')
                            .then((_) => ref.invalidate(payoutMethodsProvider)),
                        child: Text(
                          'Manage',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...list.map((m) => _PayoutMethodTile(
                        method: m,
                        selected: _methodId == m.id,
                        onTap: () => setState(() => _methodId = m.id),
                      )),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: vc.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: vc.border),
                    ),
                    child: PayoutMethodForm(
                      title: 'Add a payout method to withdraw',
                      onSaved: (method) {
                        ref.invalidate(payoutMethodsProvider);
                        setState(() => _methodId = method.id);
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                if (_amountPaise > 0) ...[
                  _SummaryTable(
                    amountPaise: _amountPaise,
                    feePaise: _feePaise,
                    netPaise: _netPaise,
                  ),
                  const SizedBox(height: 20),
                ],

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading || _methodId == null || _amountPaise <= 0
                        ? null
                        : () => _submit(list),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Withdraw Now',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
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

class _PayoutMethodTile extends StatelessWidget {
  const _PayoutMethodTile({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final PayoutMethod method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final vc = HalchalColors.of(context);
    final primary = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? primary.withValues(alpha: 0.06) : vc.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? primary : vc.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              method.label.toLowerCase().contains('upi')
                  ? Icons.phone_android
                  : Icons.account_balance,
              size: 20,
              color: selected ? primary : vc.muted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: vc.onSurface,
                    ),
                  ),
                  Text(
                    method.accountMasked,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: vc.muted,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: primary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SummaryTable extends StatelessWidget {
  const _SummaryTable({
    required this.amountPaise,
    required this.feePaise,
    required this.netPaise,
  });

  final int amountPaise;
  final int feePaise;
  final int netPaise;

  @override
  Widget build(BuildContext context) {
    final vc = HalchalColors.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: vc.border),
      ),
      child: Column(
        children: [
          _Row(label: 'Amount', value: formatPaise(amountPaise), vc: vc),
          const SizedBox(height: 8),
          _Row(
            label: 'Platform fee (1.5%)',
            value: '- ${formatPaise(feePaise)}',
            vc: vc,
            valueColor: vc.muted,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: vc.border),
          ),
          _Row(
            label: 'You receive',
            value: formatPaise(netPaise),
            vc: vc,
            bold: true,
            valueColor: vc.money,
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    required this.vc,
    this.bold = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final HalchalColors vc;
  final bool bold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: vc.muted,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: valueColor ?? vc.onSurface,
          ),
        ),
      ],
    );
  }
}
