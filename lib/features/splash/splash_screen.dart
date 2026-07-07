import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../theme/halchal_colors.dart';
import '../auth/widgets/auth_app_icon.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _splashDelay = Duration(milliseconds: 2400);
  static const _authPollInterval = Duration(milliseconds: 50);

  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _scale = Tween<double>(begin: 0.72, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.6, curve: Curves.easeOut),
      ),
    );
    _controller.forward();
    _navigationTimer = Timer(_splashDelay, _navigateAfterSplash);
  }

  void _navigateAfterSplash() {
    if (!mounted) return;

    final status = ref.read(authStateProvider);
    if (status == AuthStatus.unknown) {
      _navigationTimer = Timer(_authPollInterval, _navigateAfterSplash);
      return;
    }

    context.go(status == AuthStatus.authed ? '/dashboard' : '/onboarding');
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vc = HalchalColors.of(context);
    return Scaffold(
      backgroundColor: vc.deepSurface,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.2),
            radius: 1.1,
            colors: [
              Color.lerp(vc.deepSurface, vc.primary, 0.15)!,
              vc.deepSurface,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _fade.value,
                  child: Transform.scale(
                    scale: _scale.value,
                    child: child,
                  ),
                );
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 178,
                    height: 178,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: vc.primary.withValues(alpha: 0.34),
                          blurRadius: 58,
                          spreadRadius: 8,
                        ),
                        BoxShadow(
                          color: vc.onPrimary.withValues(alpha: 0.18),
                          blurRadius: 46,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const AuthAppIcon.splash(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
