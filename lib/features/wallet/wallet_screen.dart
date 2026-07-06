import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api/api_client.dart';
import '../../core/format/money_format.dart';
import '../../core/layout/app_spacing.dart';
import '../../core/layout/list_entrance.dart';
import '../../theme/viralcut_colors.dart';
import '../profile/profile_providers.dart';
import 'wallet_providers.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletProvider);
    final transactions = ref.watch(walletTransactionsProvider);
    final me = ref.watch(profileMeProvider);
    final clipsUnderReview = ref.watch(clipsUnderReviewCountProvider);

    return wallet.when(
      loading: () => const ScreenLoader(),
      error: (e, _) => Center(child: Text('$e')),
      data: (w) {
        final kycStatus = me.valueOrNull?['kycStatus'] as String? ?? 'pending';
        final animKey = '${w.availablePaise}|${w.pendingPaise}|${w.lifetimePaise}';

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(walletProvider);
            ref.invalidate(walletTransactionsProvider);
          },
          child: ScreenStaggeredColumn(
            animationKey: animKey,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenHorizontal,
              AppSpacing.sm,
              AppSpacing.screenHorizontal,
              AppSpacing.floatingNavBottom(context),
            ),
            children: [
              _BalanceCard(
                wallet: w,
                clipsUnderReview: clipsUnderReview.valueOrNull ?? 0,
                onWithdraw: () => context.push('/withdraw'),
                onViewClips: () => context.go('/submissions'),
              ),
              const SizedBox(height: 16),
              if (kycStatus != 'verified')
                _KycWarningCard(kycStatus: kycStatus),
              if (kycStatus != 'verified') const SizedBox(height: 16),
              _EarningsOverview(wallet: w),
              const SizedBox(height: 24),
              _TransactionSection(transactions: transactions),
            ],
          ),
        );
      },
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.wallet,
    required this.clipsUnderReview,
    required this.onWithdraw,
    required this.onViewClips,
  });

  final WalletData wallet;
  final int clipsUnderReview;
  final VoidCallback onWithdraw;
  final VoidCallback onViewClips;

  @override
  Widget build(BuildContext context) {
    final vc = ViralCutColors.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: vc.deepSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: label + View analytics button
          Row(
            children: [
              Text(
                'Total earned',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white60,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onViewClips,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white24),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bar_chart_rounded, size: 14, color: Colors.white70),
                      const SizedBox(width: 5),
                      Text(
                        'View analytics',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(Icons.chevron_right_rounded, size: 14, color: Colors.white54),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Large total earned amount
          Text(
            formatPaise(wallet.lifetimePaise),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 42,
              fontWeight: FontWeight.w800,
              color: vc.moneyBright,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
          const SizedBox(height: 16),
          // Bottom 3-column row
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Col 1: Pending
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pending',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.white54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatPaise(wallet.pendingPaise),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: vc.moneyBright,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.schedule_rounded, size: 11, color: Colors.white38),
                          const SizedBox(width: 3),
                          Text(
                            'Available soon',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: Colors.white38,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                VerticalDivider(color: Colors.white.withValues(alpha: 0.1), width: 24),
                // Col 2: Clips under review
                Expanded(
                  child: GestureDetector(
                    onTap: onViewClips,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$clipsUnderReview',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: vc.primary,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'Clips under review',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.white54,
                                ),
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.chevron_right_rounded, size: 13, color: Colors.white38),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                VerticalDivider(color: Colors.white.withValues(alpha: 0.1), width: 24),
                // Col 3: Withdraw
                Expanded(
                  child: GestureDetector(
                    onTap: onWithdraw,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Withdraw',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'Transfer to bank',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.white54,
                                ),
                              ),
                            ),
                            const SizedBox(width: 3),
                            const Icon(Icons.arrow_forward_rounded, size: 12, color: Colors.white54),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KycWarningCard extends StatelessWidget {
  const _KycWarningCard({required this.kycStatus});

  final String kycStatus;

  @override
  Widget build(BuildContext context) {
    final vc = ViralCutColors.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: vc.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: vc.warning.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 20, color: vc.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              kycStatus == 'under_review'
                  ? 'Your KYC is under review. Withdrawals will be enabled once verified.'
                  : 'Complete KYC to unlock withdrawals. Withdrawals are not blocked in v1.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: vc.warning,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EarningsOverview extends StatelessWidget {
  const _EarningsOverview({required this.wallet});

  final WalletData wallet;

  @override
  Widget build(BuildContext context) {
    final vc = ViralCutColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'EARNINGS OVERVIEW',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: vc.muted,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatBox(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Total earned',
                value: formatPaise(wallet.lifetimePaise),
                valueColor: vc.money,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatBox(
                icon: Icons.check_circle_outline_rounded,
                label: 'Available',
                value: formatPaise(wallet.availablePaise),
                valueColor: vc.onSurface,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatBox(
                icon: Icons.schedule_rounded,
                label: 'Pending',
                value: formatPaise(wallet.pendingPaise),
                valueColor: vc.muted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final vc = ViralCutColors.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: vc.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: vc.muted),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: vc.muted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionSection extends StatelessWidget {
  const _TransactionSection({required this.transactions});

  final AsyncValue<List<TransactionItem>> transactions;

  @override
  Widget build(BuildContext context) {
    final vc = ViralCutColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TRANSACTION HISTORY',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: vc.muted,
          ),
        ),
        const SizedBox(height: 12),
        transactions.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Could not load transactions', style: TextStyle(color: vc.muted)),
          data: (list) {
            if (list.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No transactions yet',
                    style: GoogleFonts.inter(color: vc.muted),
                  ),
                ),
              );
            }
            return Column(
              children: list.map((tx) => _TransactionRow(tx: tx)).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.tx});

  final TransactionItem tx;

  @override
  Widget build(BuildContext context) {
    final vc = ViralCutColors.of(context);
    final isCredit = tx.amountPaise > 0 || tx.type == 'earning';
    final label = switch (tx.type) {
      'earning' => 'Campaign earning',
      'withdrawal' => 'Withdrawal',
      'refund' => 'Refund',
      'bonus' => 'Bonus',
      _ => tx.type,
    };
    final icon = switch (tx.type) {
      'earning' => Icons.trending_up,
      'withdrawal' => Icons.arrow_upward,
      'refund' => Icons.replay,
      _ => Icons.receipt_outlined,
    };

    DateTime? parsedDate;
    try {
      parsedDate = DateTime.parse(tx.createdAt);
    } catch (_) {}

    final dateStr = parsedDate != null
        ? '${parsedDate.day} ${_month(parsedDate.month)} ${parsedDate.year}'
        : tx.createdAt;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: vc.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isCredit
                  ? vc.money.withValues(alpha: 0.1)
                  : vc.muted.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 18,
              color: isCredit ? vc.money : vc.muted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: vc.onSurface,
                  ),
                ),
                Text(
                  dateStr,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: vc.muted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : ''}${formatPaise(tx.amountPaise)}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isCredit ? vc.money : vc.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  String _month(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ][m];
}
