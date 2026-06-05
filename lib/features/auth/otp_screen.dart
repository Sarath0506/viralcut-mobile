import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import '../../theme/token_colors.dart';
import 'widgets/auth_page_layout.dart';
import 'widgets/auth_switch_link.dart';
import 'widgets/auth_ui.dart';
import 'widgets/otp_pin_input.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _pinKey = GlobalKey<OtpPinInputState>();
  bool _verifying = false;
  bool _resending = false;

  String get _phone =>
      GoRouterState.of(context).uri.queryParameters['phone'] ?? '';

  String get _flow =>
      GoRouterState.of(context).uri.queryParameters['flow'] ?? 'login';

  String? get _displayName {
    final name =
        GoRouterState.of(context).uri.queryParameters['name']?.trim();
    return name != null && name.isNotEmpty ? name : null;
  }

  bool get _isSignup => _flow == 'signup';

  String get _backRoute => _isSignup ? '/signup' : '/login';

  void _goBackToPhone() {
    if (mounted) context.go(_backRoute);
  }

  Future<void> _resendOtp() async {
    if (_phone.isEmpty || _resending) return;
    setState(() => _resending = true);
    try {
      await ref.read(apiClientProvider).requestOtp(_phone);
      _pinKey.currentState?.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP resent.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _verify(String code) async {
    if (_phone.isEmpty || _verifying) return;

    setState(() => _verifying = true);
    try {
      final session = await ref.read(apiClientProvider).verifyOtp(
            phone: _phone,
            code: code,
            displayName: _isSignup ? _displayName : null,
          );
      await ref.read(authStateProvider.notifier).login(session);
      if (mounted) context.go('/dashboard');
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating),
        );
        _goBackToPhone();
      }
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final masked = _phone.length >= 4
        ? '******${_phone.substring(_phone.length - 4)}'
        : _phone;

    return AuthPageLayout(
      title: 'Enter OTP',
      subtitle: 'We sent a 6-digit code to $masked',
      showBack: true,
      onBack: _goBackToPhone,
      footer: AuthSwitchLink(
        leadText: _isSignup ? 'Already have an account? ' : 'New to ViralCut? ',
        linkText: _isSignup ? 'Log in' : 'Sign up',
        route: _isSignup ? '/login' : '/signup',
      ),
      form: AuthFormCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OtpPinInput(
              key: _pinKey,
              enabled: !_verifying,
              onCompleted: _verify,
            ),
            if (_verifying) ...[
              const SizedBox(height: 20),
              const Center(child: CircularProgressIndicator()),
            ],
            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: _resending || _phone.isEmpty ? null : _resendOtp,
                child: Text(
                  _resending ? 'Sending…' : 'Resend OTP',
                  style: AuthUi.bodyFont(context).copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
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
