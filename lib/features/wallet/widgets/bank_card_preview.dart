import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/layout/app_spacing.dart';
import '../../../theme/halchal_colors.dart';

/// Masks all but the last 4 digits of a bank account number.
///
/// Non-digit characters are stripped first, so this works both for a raw
/// in-progress entry and an already server-masked value (e.g. "••••1234")
/// — in the latter case only the digits the server already disclosed are
/// available to show.
String maskAccountNumber(String value, bool revealed) {
  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return '';
  if (revealed) return _spaceGroup(digits);
  final last4 = digits.length <= 4 ? digits : digits.substring(digits.length - 4);
  return '•••• •••• $last4';
}

String _spaceGroup(String digits) {
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && i % 4 == 0) buffer.write(' ');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// Live visual preview of the bank account being entered/edited, styled
/// like a physical debit card. Purely presentational — the parent screen
/// owns the form controllers and passes the current values down.
class BankCardPreview extends StatelessWidget {
  const BankCardPreview({
    super.key,
    required this.bankName,
    required this.holderName,
    required this.accountNumber,
    required this.ifsc,
    required this.revealed,
  });

  final String bankName;
  final String holderName;
  final String accountNumber;
  final String ifsc;
  final bool revealed;

  @override
  Widget build(BuildContext context) {
    final vc = HalchalColors.of(context);

    final bank = bankName.trim();
    final holder = holderName.trim();
    final ifscValue = ifsc.trim();
    final masked = maskAccountNumber(accountNumber, revealed);

    final bankLabel = bank.isEmpty ? 'BANK' : bank.toUpperCase();
    final holderLabel = holder.isEmpty ? 'YOUR NAME' : holder.toUpperCase();
    final ifscLabel = ifscValue.isEmpty ? '----------' : ifscValue.toUpperCase();
    final numberLabel = masked.isEmpty ? '••••••••••' : masked;

    final digits = accountNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final hasDigits = digits.isNotEmpty;
    final lastDigits = digits.length <= 4 ? digits : digits.substring(digits.length - 4);
    final numberDescription = !hasDigits
        ? 'not entered'
        : revealed
            ? '$numberLabel, fully visible'
            : 'hidden, ending $lastDigits';

    return Semantics(
      label: '$bankLabel bank card. Account holder $holderLabel. '
          'Account number $numberDescription.',
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [vc.primary, vc.primaryVariant],
            ),
            boxShadow: [
              BoxShadow(
                color: vc.primary.withValues(alpha: 0.28),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.account_balance_rounded, size: 20, color: vc.onPrimary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      bankLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        color: vc.onPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  Icon(Icons.wifi_rounded, size: 22, color: vc.onPrimary.withValues(alpha: 0.85)),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  numberLabel,
                  key: ValueKey(revealed),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: vc.onPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.2,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('HOLDER', style: _labelStyle(vc)),
                        const SizedBox(height: 2),
                        Text(
                          holderLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _valueStyle(vc),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('IFSC', style: _labelStyle(vc)),
                      const SizedBox(height: 2),
                      Text(ifscLabel, style: _valueStyle(vc)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _labelStyle(HalchalColors vc) => GoogleFonts.inter(
        color: vc.onPrimary.withValues(alpha: 0.66),
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      );

  TextStyle _valueStyle(HalchalColors vc) => GoogleFonts.plusJakartaSans(
        color: vc.onPrimary,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      );
}

/// "Show/hide full account number" control paired with [BankCardPreview].
/// Shared by every screen that lets a user reveal what they've entered.
class BankCardRevealToggle extends StatelessWidget {
  const BankCardRevealToggle({
    super.key,
    required this.revealed,
    required this.onTap,
  });

  final bool revealed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final vc = HalchalColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              revealed ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 16,
              color: vc.muted,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              revealed ? 'Hide full account number' : 'Show full account number',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: vc.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
