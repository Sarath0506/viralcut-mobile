
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/layout/app_spacing.dart';
import '../../theme/halchal_colors.dart';
import '../../theme/halchal_text_styles.dart';
import '../auth/widgets/auth_app_icon.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _advance() {
    if (_page == 0) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      context.go('/signup');
    }
  }

  @override
  Widget build(BuildContext context) {
    final vc = HalchalColors.of(context);

    return Scaffold(
      backgroundColor: vc.background,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                AppSpacing.sm,
                AppSpacing.sm,
                0,
              ),
              child: SizedBox(
                height: AppSpacing.minTouchTarget,
                child: Row(
                  children: [
                    const AuthAppIcon.header(),
                    const SizedBox(width: 8),
                    Text(
                      'Halchal',
                      style: HalchalTextStyles.meta(context).copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: vc.onSurface,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => context.go('/signup'),
                      child: Text(
                        'Skip',
                        style: HalchalTextStyles.meta(context).copyWith(
                          color: vc.muted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: _advance,
                behavior: HitTestBehavior.opaque,
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _page = i),
                  children: [
                    const _WalletOnboardingSlide(),
                    const _MarketplaceOnboardingSlide(),
                  ],
                ),
              ),
            ),
            _OnboardingBottom(
              page: _page,
              onLogin: () => context.go('/login'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingBottom extends StatelessWidget {
  const _OnboardingBottom({required this.page, required this.onLogin});

  final int page;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final vc = HalchalColors.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final bottomSafe = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.md,
        AppSpacing.screenHorizontal,
        bottomSafe > 0 ? bottomSafe : AppSpacing.screenBottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PageDots(activeIndex: page, count: 2),
          const SizedBox(height: AppSpacing.lg),
          TextButton(
            onPressed: onLogin,
            child: RichText(
              text: TextSpan(
                style: HalchalTextStyles.meta(context).copyWith(
                  color: vc.muted,
                  fontSize: 14,
                ),
                children: [
                  const TextSpan(text: 'Already have an account? '),
                  TextSpan(
                    text: 'Log in',
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.activeIndex, required this.count});

  final int activeIndex;
  final int count;

  @override
  Widget build(BuildContext context) {
    final vc = HalchalColors.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? primary : vc.border,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }
}

// ─── Slide 1: Wallet / earnings ─────────────────────────────────────────────

class _WalletOnboardingSlide extends StatelessWidget {
  const _WalletOnboardingSlide();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Expanded(
          child: Center(
            child: _IllustratedHero(
              assetPath: 'assets/images/onboarding_hero.svg',
            ),
          ),
        ),
        _OnboardingTextBlock(
          title: 'Post clips.\nGet paid.',
          titleHighlight: 'Get paid.',
          subtitle:
              'Regional-first clipping platform. No camera.\nNo face. Just views and earnings.',
        ),
      ],
    );
  }
}

/// Shared onboarding hero: a licensed, professionally illustrated scene
/// (unDraw), tinted to the brand purple, with a soft ambient glow, a
/// one-time entrance reveal, and a slow continuous float. Reused across
/// slides with a different [assetPath] so every slide gets the same
/// polish instead of one-off hand-built illustrations.
class _IllustratedHero extends StatefulWidget {
  const _IllustratedHero({required this.assetPath});

  final String assetPath;

  @override
  State<_IllustratedHero> createState() => _IllustratedHeroState();
}

class _IllustratedHeroState extends State<_IllustratedHero>
    with TickerProviderStateMixin {
  late final AnimationController _float;
  late final AnimationController _breathe;
  late final AnimationController _reveal;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _breathe = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    )..repeat(reverse: true);
    _reveal = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    )..forward();
  }

  @override
  void dispose() {
    _float.dispose();
    _breathe.dispose();
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vc = HalchalColors.of(context);

    return SizedBox(
      width: 320,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Ambient breathing glow behind the illustration.
          AnimatedBuilder(
            animation: _breathe,
            builder: (context, child) => Transform.scale(
              scale: 1.0 + 0.05 * _breathe.value,
              child: child,
            ),
            child: Container(
              width: 300,
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(160),
                gradient: RadialGradient(
                  colors: [
                    vc.primary.withValues(alpha: 0.30),
                    vc.primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          // Illustration: pops in on mount, then floats gently forever.
          AnimatedBuilder(
            animation: Listenable.merge([_float, _reveal]),
            builder: (context, child) {
              final reveal = Curves.easeOutBack.transform(_reveal.value);
              return Opacity(
                opacity: _reveal.value,
                child: Transform.translate(
                  offset: Offset(
                    0,
                    (_float.value - 0.5) * 10 + (1 - reveal) * 24,
                  ),
                  child: Transform.scale(
                    scale: 0.9 + 0.1 * reveal,
                    child: child,
                  ),
                ),
              );
            },
            child: SvgPicture.asset(
              widget.assetPath,
              width: 300,
            ),
          ),
        ],
      ),
    );
  }
}


// ─── Slide 2: Campaign marketplace ──────────────────────────────────────────

class _MarketplaceOnboardingSlide extends StatelessWidget {
  const _MarketplaceOnboardingSlide();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Expanded(
          child: Center(
            child: _IllustratedHero(
              assetPath: 'assets/images/onboarding_hero_marketplace.svg',
            ),
          ),
        ),
        _OnboardingTextBlock(
          title: 'Pick any\nbrand campaign',
          subtitle:
              'Browse live campaigns from top Indian brands.\nChoose what fits your audience.',
        ),
      ],
    );
  }
}

// ─── Shared text block ───────────────────────────────────────────────────────

class _OnboardingTextBlock extends StatelessWidget {
  const _OnboardingTextBlock({
    required this.title,
    this.titleHighlight,
    this.subtitle,
  });

  final String title;
  final String? titleHighlight;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final vc = HalchalColors.of(context);
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (titleHighlight != null)
            RichText(
              text: TextSpan(
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: vc.onSurface,
                  height: 1.15,
                ),
                children: title.split('\n').expand((line) {
                  final isHighlight = line.trim() == titleHighlight!.trim();
                  return [
                    TextSpan(
                      text: '$line\n',
                      style: isHighlight ? TextStyle(color: primary) : null,
                    ),
                  ];
                }).toList(),
              ),
            )
          else
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: vc.onSurface,
                height: 1.15,
              ),
            ),
          if (subtitle != null) ...[
            const SizedBox(height: 12),
            Text(
              subtitle!,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: vc.muted,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
