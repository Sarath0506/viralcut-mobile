import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/format/phone_format.dart';
import 'widgets/auth_page_layout.dart';
import 'widgets/auth_switch_link.dart';
import 'widgets/auth_ui.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _countryController = TextEditingController(text: '+91');
  final _phoneController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _countryController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String? get _phoneE164 => normalizeIndiaPhone(
        countryCode: _countryController.text,
        localNumber: _phoneController.text,
      );

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
      ),
    );
  }

  Future<void> _sendOtpAndContinue() async {
    final phone = _phoneE164;
    if (phone == null) {
      _showError('Please enter a valid 10-digit phone number.');
      return;
    }

    setState(() => _busy = true);
    try {
      await ref.read(apiClientProvider).requestOtp(phone);
      if (!mounted) return;
      context.push(
        Uri(
          path: '/otp',
          queryParameters: {'phone': phone, 'flow': 'login'},
        ).toString(),
      );
    } on ApiException catch (e) {
      if (mounted) _showError(e.message);
    } catch (_) {
      if (mounted) _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageLayout(
      showBack: true,
      onBack: () => context.go('/onboarding'),
      headerTitle: 'Welcome back',
      title: 'Log in',
      titleHighlight: 'in',
      subtitle: 'Continue earning from your clips.',
      footer: const AuthSwitchLink(
        leadText: 'New to Halchal? ',
        linkText: 'Sign up',
        route: '/signup',
      ),
      form: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthLabeledField(
            label: 'Phone or email',
            child: AuthPhoneRow(
              countryController: _countryController,
              phoneController: _phoneController,
            ),
          ),
          const SizedBox(height: 28),
          AuthPrimaryButton(
            label: 'Log in',
            loading: _busy,
            onPressed: _busy ? null : _sendOtpAndContinue,
          ),
        ],
      ),
    );
  }
}
