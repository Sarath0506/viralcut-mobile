import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/format/phone_format.dart';
import '../../theme/viralcut_colors.dart';
import 'widgets/auth_page_layout.dart';
import 'widgets/auth_switch_link.dart';
import 'widgets/auth_ui.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _countryController = TextEditingController(text: '+91');
  final _phoneController = TextEditingController();
  bool _busy = false;
  String? _lastOtpPhone;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_tryAdvance);
    _emailController.addListener(_tryAdvance);
    _phoneController.addListener(_tryAdvance);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _countryController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String? get _phoneE164 => normalizeIndiaPhone(
        countryCode: _countryController.text,
        localNumber: _phoneController.text,
      );

  bool _isValidEmail(String value) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value);
  }

  bool get _isFormComplete {
    if (_phoneE164 == null) return false;
    if (_nameController.text.trim().length < 2) return false;
    return _isValidEmail(_emailController.text.trim());
  }

  void _tryAdvance() {
    final digits = _phoneController.text;
    if (digits.length < 10) {
      _lastOtpPhone = null;
      return;
    }
    if (_busy) return;

    final phone = _phoneE164;
    if (phone == null) {
      if (digits.length == 10 &&
          _nameController.text.trim().length >= 2 &&
          _isValidEmail(_emailController.text.trim()) &&
          mounted) {
        _showError(kInvalidIndiaPhoneMessage);
      }
      _lastOtpPhone = null;
      return;
    }
    if (!_isFormComplete) return;
    if (phone == _lastOtpPhone) return;
    _lastOtpPhone = phone;
    _sendOtpAndContinue();
  }

  Future<void> _sendOtpAndContinue() async {
    if (!_isFormComplete) {
      _showError('Please fill in all fields correctly.');
      return;
    }
    final phone = _phoneE164;
    if (phone == null) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    setState(() => _busy = true);
    try {
      await ref.read(apiClientProvider).requestOtp(phone);
      if (!mounted) return;
      context.push(
        Uri(
          path: '/otp',
          queryParameters: {
            'phone': phone,
            'flow': 'signup',
            'name': name,
            'email': email,
          },
        ).toString(),
      );
    } on ApiException catch (e) {
      _lastOtpPhone = null;
      if (mounted) _showError(e.message);
    } catch (_) {
      _lastOtpPhone = null;
      if (mounted) _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vc = ViralCutColors.of(context);
    return AuthPageLayout(
      showBack: true,
      onBack: () => context.go('/onboarding'),
      headerTitle: 'Create account',
      title: 'Welcome to Halchal',
      titleHighlight: 'Halchal',
      subtitle: 'Join the elite network of digital entrepreneurs.',
      footer: const AuthSwitchLink(
        leadText: 'Already have an account? ',
        linkText: 'Log in',
        route: '/login',
      ),
      form: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthLabeledField(
            label: 'Full name',
            child: AuthTextFormField(
              controller: _nameController,
              hint: 'Enter your full name',
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.person_outline,
            ),
          ),
          const SizedBox(height: 16),
          AuthLabeledField(
            label: 'Phone',
            child: AuthPhoneRow(
              countryController: _countryController,
              phoneController: _phoneController,
            ),
          ),
          const SizedBox(height: 16),
          AuthLabeledField(
            label: 'Email',
            child: AuthTextFormField(
              controller: _emailController,
              hint: 'name@company.com',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              prefixIcon: Icons.mail_outline,
            ),
          ),
          const SizedBox(height: 24),
          AuthPrimaryButton(
            label: 'Create account',
            loading: _busy,
            onPressed: _busy ? null : _sendOtpAndContinue,
          ),
          const SizedBox(height: 16),
          Text(
            'By creating an account you agree to our Terms of Service and Privacy Policy.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: vc.muted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
