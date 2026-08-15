import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import 'widgets/auth_page_layout.dart';
import 'widgets/auth_switch_link.dart';
import 'widgets/auth_ui.dart';
import 'widgets/otp_pin_input.dart';
import 'widgets/otp_status_icon.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _pinKey = GlobalKey<OtpPinInputState>();
  OtpStatus _status = OtpStatus.idle;
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

  String? get _email {
    final email =
        GoRouterState.of(context).uri.queryParameters['email']?.trim();
    return email != null && email.isNotEmpty ? email : null;
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
    if (_phone.isEmpty || _status == OtpStatus.verifying) return;

    final reduceMotion = MediaQuery.of(context).disableAnimations;

    setState(() => _status = OtpStatus.verifying);

    try {
      final session = await ref.read(apiClientProvider).verifyOtp(
            phone: _phone,
            code: code,
            displayName: _isSignup ? _displayName : null,
            email: _isSignup ? _email : null,
          );
      if (!mounted) return;
      setState(() => _status = OtpStatus.verified);
      if (!reduceMotion) {
        // Brief hold so the "Verified" state is visible before navigating
        // away — without this, the router's reactive redirect (triggered
        // by login() below) fires instantly and the state never renders.
        await Future.delayed(const Duration(milliseconds: 900));
      }
      if (!mounted) return;
      // authStateProvider flipping to authed is what actually triggers
      // navigation (app_router.dart's redirect bounces authed users off
      // /otp to /dashboard) — calling login() any earlier than this would
      // have fired that redirect immediately, skipping the reveal above.
      await ref.read(authStateProvider.notifier).login(session);
    } on ApiException catch (e) {
      if (mounted) {
        _pinKey.currentState?.clear();
        setState(() => _status = OtpStatus.idle);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final masked = _phone.length >= 4
        ? '******${_phone.substring(_phone.length - 4)}'
        : _phone;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return AuthPageLayout(
      title: 'Enter OTP',
      subtitle: 'We sent a 6-digit code to $masked',
      showBack: true,
      onBack: _goBackToPhone,
      footer: AuthSwitchLink(
        leadText: _isSignup ? 'Already have an account? ' : 'New to Halchal? ',
        linkText: _isSignup ? 'Log in' : 'Sign up',
        route: _isSignup ? '/login' : '/signup',
      ),
      form: AnimatedScale(
        scale: _status == OtpStatus.verifying ? 1.08 : 1.0,
        duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 450),
        curve: Curves.easeOutBack,
        child: AuthFormCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OtpPinInput(
                key: _pinKey,
                status: _status,
                enabled: _status == OtpStatus.idle,
                onCompleted: _verify,
              ),
              const SizedBox(height: 20),
              Center(child: OtpStatusIcon(status: _status)),
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
      ),
    );
  }
}
