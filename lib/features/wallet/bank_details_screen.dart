import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/layout/app_spacing.dart';
import '../../theme/halchal_colors.dart';
import 'widgets/bank_card_preview.dart';
import 'withdraw_screen.dart';

final _ifscPattern = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');

class BankDetailsScreen extends ConsumerStatefulWidget {
  const BankDetailsScreen({super.key});

  @override
  ConsumerState<BankDetailsScreen> createState() => _BankDetailsScreenState();
}

class _BankDetailsScreenState extends ConsumerState<BankDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _accountCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _upiCtrl = TextEditingController();

  bool _saving = false;
  bool _loading = true;
  bool _dirty = false;
  bool _revealed = false;
  bool _revealing = false;
  String? _fullAccountNumber;

  // Existing saved methods
  PayoutMethod? _existingBank;
  PayoutMethod? _existingUpi;

  bool get _hasAccountNumber =>
      _existingBank != null || _accountCtrl.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    for (final c in [_nameCtrl, _accountCtrl, _ifscCtrl, _bankNameCtrl, _upiCtrl]) {
      c.addListener(_onChanged);
    }
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    try {
      final methods = await ref.read(apiClientProvider).fetchPayoutMethods();
      final bank = methods.where((m) => m.type == 'bank').firstOrNull;
      final upi = methods.where((m) => m.type == 'upi').firstOrNull;

      if (!mounted) return;
      setState(() {
        _existingBank = bank;
        _existingUpi = upi;
        _loading = false;
      });

      if (bank != null) {
        _nameCtrl.text = bank.accountHolderName;
        _ifscCtrl.text = bank.ifscCode ?? '';
        _bankNameCtrl.text = bank.bankName ?? bank.label;
      }
      if (upi != null) {
        _upiCtrl.text = upi.accountMasked;
      }
      // After pre-fill, reset dirty — changes after this point are real edits
      setState(() => _dirty = false);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onChanged() {
    if (!_dirty) setState(() => _dirty = true);
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _accountCtrl, _ifscCtrl, _bankNameCtrl, _upiCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _toggleRevealed() async {
    if (_revealed) {
      setState(() => _revealed = false);
      return;
    }
    if (_existingBank == null || _fullAccountNumber != null) {
      setState(() => _revealed = true);
      return;
    }
    setState(() => _revealing = true);
    try {
      final full =
          await ref.read(apiClientProvider).revealPayoutMethodAccountNumber(_existingBank!.id);
      if (!mounted) return;
      setState(() {
        _fullAccountNumber = full;
        _revealed = true;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _revealing = false);
    }
  }

  Future<void> _delete() async {
    final vc = HalchalColors.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete bank details?'),
        content: const Text('This will remove your saved bank account and UPI details.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: vc.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    try {
      if (_existingBank != null) {
        await ref.read(apiClientProvider).deletePayoutMethod(_existingBank!.id);
      }
      if (_existingUpi != null) {
        await ref.read(apiClientProvider).deletePayoutMethod(_existingUpi!.id);
      }
      ref.invalidate(payoutMethodsProvider);
      if (!mounted) return;
      _nameCtrl.clear();
      _accountCtrl.clear();
      _ifscCtrl.clear();
      _bankNameCtrl.clear();
      _upiCtrl.clear();
      setState(() {
        _existingBank = null;
        _existingUpi = null;
        _dirty = false;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bank details removed')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final bankName = _bankNameCtrl.text.trim();
      final name = _nameCtrl.text.trim();
      final ifsc = _ifscCtrl.text.trim().toUpperCase();
      final account = _accountCtrl.text.trim();
      final upi = _upiCtrl.text.trim();

      if (_existingBank != null) {
        // Update existing bank method (name/IFSC/bankName only — account stays)
        await ref.read(apiClientProvider).updatePayoutMethod(
              _existingBank!.id,
              accountHolderName: name,
              ifscCode: ifsc.isNotEmpty ? ifsc : null,
              bankName: bankName.isNotEmpty ? bankName : null,
              label: bankName.isNotEmpty ? bankName : null,
            );
      } else {
        // Create new bank method — account number required
        await ref.read(apiClientProvider).createPayoutMethod(
              type: 'bank',
              label: bankName,
              accountHolderName: name,
              account: account,
              ifscCode: ifsc.isNotEmpty ? ifsc : null,
              bankName: bankName.isNotEmpty ? bankName : null,
            );
      }

      // Handle UPI
      if (upi.isNotEmpty && _existingUpi == null) {
        await ref.read(apiClientProvider).createPayoutMethod(
              type: 'upi',
              label: 'UPI',
              accountHolderName: name,
              account: upi,
            );
      } else if (upi.isNotEmpty && _existingUpi != null) {
        await ref.read(apiClientProvider).updatePayoutMethod(
              _existingUpi!.id,
              accountHolderName: name,
            );
      }

      ref.invalidate(payoutMethodsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bank details saved')),
      );
      setState(() => _dirty = false);
      await _loadExisting();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vc = HalchalColors.of(context);

    return Scaffold(
      backgroundColor: vc.background,
      appBar: AppBar(
        backgroundColor: vc.background,
        surfaceTintColor: vc.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: vc.onSurface),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: Text(
          'Bank Details',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: vc.onSurface,
          ),
        ),
        actions: [
          if (_existingBank != null)
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: vc.error),
              onPressed: _saving ? null : _delete,
              tooltip: 'Delete bank details',
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.screenHorizontal,
                            AppSpacing.md,
                            AppSpacing.screenHorizontal,
                            AppSpacing.md,
                          ),
                          child: Column(
                            children: [
                              BankCardPreview(
                                bankName: _bankNameCtrl.text,
                                holderName: _nameCtrl.text,
                                accountNumber: _existingBank != null
                                    ? (_revealed && _fullAccountNumber != null
                                        ? _fullAccountNumber!
                                        : _existingBank!.accountMasked)
                                    : _accountCtrl.text,
                                ifsc: _ifscCtrl.text,
                                revealed: _revealed,
                              ),
                              if (_hasAccountNumber) ...[
                                const SizedBox(height: AppSpacing.sm),
                                _revealing
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2, color: vc.muted),
                                          ),
                                          const SizedBox(width: AppSpacing.xs),
                                          Text(
                                            'Loading full account number…',
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: vc.muted),
                                          ),
                                        ],
                                      )
                                    : BankCardRevealToggle(
                                        revealed: _revealed,
                                        onTap: _toggleRevealed,
                                      ),
                              ],
                            ],
                          ),
                        ),
                        Divider(height: 1, thickness: 0.5, color: vc.border),
                        _FormRow(
                          icon: Icons.credit_card_outlined,
                          label: 'Name',
                          required: true,
                          controller: _nameCtrl,
                          placeholder: 'Account holder name',
                          validator: (v) =>
                              (v == null || v.trim().length < 2) ? 'Required' : null,
                        ),
                        // Account number: editable only when no existing method
                        if (_existingBank == null)
                          _FormRow(
                            icon: Icons.tag_rounded,
                            label: 'Account No.',
                            required: true,
                            controller: _accountCtrl,
                            placeholder: 'Bank account number',
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            validator: (v) =>
                                (v == null || v.trim().length < 6) ? 'Required' : null,
                          )
                        else
                          _ReadOnlyRow(
                            icon: Icons.tag_rounded,
                            label: 'Account No.',
                            value: _existingBank!.accountMasked,
                          ),
                        _FormRow(
                          icon: Icons.account_balance_outlined,
                          label: 'IFSC',
                          required: _existingBank == null,
                          controller: _ifscCtrl,
                          placeholder: 'e.g. HDFC0001234',
                          textCapitalization: TextCapitalization.characters,
                          inputFormatters: [_UpperCaseFormatter()],
                          validator: _existingBank != null
                              ? null
                              : (v) {
                                  final s = v?.trim() ?? '';
                                  return _ifscPattern.hasMatch(s) ? null : 'Enter valid IFSC';
                                },
                        ),
                        _FormRow(
                          icon: Icons.account_balance_outlined,
                          label: 'Bank Name',
                          required: _existingBank == null,
                          controller: _bankNameCtrl,
                          placeholder: 'e.g. HDFC Bank',
                          validator: _existingBank != null
                              ? null
                              : (v) =>
                                  (v == null || v.trim().length < 2) ? 'Required' : null,
                        ),
                        _FormRow(
                          icon: Icons.phone_android_outlined,
                          label: 'UPI ID',
                          required: false,
                          controller: _upiCtrl,
                          placeholder: _existingUpi != null
                              ? _existingUpi!.accountMasked
                              : 'e.g. name@upi (optional)',
                          isLast: true,
                        ),
                        if (_existingBank != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                            child: Row(
                              children: [
                                Icon(Icons.lock_outline_rounded, size: 13, color: vc.muted),
                                const SizedBox(width: 5),
                                Text(
                                  'To change your account number, contact support.',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: vc.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          onPressed: (_dirty && !_saving) ? _save : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: vc.onSurface,
                            disabledBackgroundColor: vc.border,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _saving
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: vc.onPrimary),
                                )
                              : Text(
                                  'Save Changes',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: _dirty ? vc.onPrimary : vc.muted,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _FormRow extends StatelessWidget {
  const _FormRow({
    required this.icon,
    required this.label,
    required this.required,
    required this.controller,
    required this.placeholder,
    this.keyboardType,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final bool required;
  final TextEditingController controller;
  final String placeholder;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final vc = HalchalColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(icon, size: 20, color: vc.onSurface),
              const SizedBox(width: 14),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: vc.onSurface,
                    ),
                  ),
                  if (required)
                    Text(
                      ' *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: vc.error,
                      ),
                    ),
                ],
              ),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  textAlign: TextAlign.right,
                  keyboardType: keyboardType,
                  inputFormatters: inputFormatters,
                  textCapitalization: textCapitalization,
                  validator: validator,
                  style: TextStyle(fontSize: 15, color: vc.onSurface),
                  decoration: InputDecoration(
                    hintText: placeholder,
                    hintStyle: TextStyle(color: vc.muted, fontSize: 15),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    errorStyle: TextStyle(
                      fontSize: 13,
                      color: vc.error,
                      height: 1.4,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(height: 1, thickness: 0.5, indent: 50, color: vc.border),
      ],
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  const _ReadOnlyRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final vc = HalchalColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(icon, size: 20, color: vc.onSurface),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: vc.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(fontSize: 15, color: vc.muted),
              ),
            ],
          ),
        ),
        Divider(height: 1, thickness: 0.5, indent: 50, color: vc.border),
      ],
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) =>
      newValue.copyWith(text: newValue.text.toUpperCase());
}
