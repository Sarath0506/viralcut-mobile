import 'package:flutter/material.dart';
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

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _pageController = PageController();
  int _page = 0;
  late final AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _floatController.dispose();
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
                    _WalletOnboardingSlide(floatAnimation: _floatController),
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
  const _WalletOnboardingSlide({required this.floatAnimation});

  final Animation<double> floatAnimation;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      children: [
        Expanded(
          child: Center(
            child: AnimatedBuilder(
              animation: floatAnimation,
              builder: (context, child) {
                final dy = (floatAnimation.value - 0.5) * 12;
                return Transform.translate(offset: Offset(0, dy), child: child);
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primary.withValues(alpha: 0.08),
                    ),
                  ),
                  _PurpleCardMockup(),
                ],
              ),
            ),
          ),
        ),
        const _OnboardingTextBlock(
          title: 'Post clips.\nGet paid.',
          titleHighlight: 'Get paid.',
          subtitle:
              'Regional-first clipping platform. No camera.\nNo face. Just views and earnings.',
        ),
      ],
    );
  }
}

class _PurpleCardMockup extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vc = HalchalColors.of(context);
    return Container(
      width: 160,
      height: 200,
      decoration: BoxDecoration(
        color: vc.primary,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.black, width: 3),
        boxShadow: [
          BoxShadow(
            color: vc.primary.withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/halchal_logo.png',
            width: 110,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          Text(
            '₹35,170',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Slide 2: Campaign marketplace ──────────────────────────────────────────

class _MarketplaceOnboardingSlide extends StatefulWidget {
  const _MarketplaceOnboardingSlide();

  @override
  State<_MarketplaceOnboardingSlide> createState() =>
      _MarketplaceOnboardingSlideState();
}

class _MarketplaceOnboardingSlideState
    extends State<_MarketplaceOnboardingSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _stagger;

  @override
  void initState() {
    super.initState();
    _stagger = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _stagger.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: _StackedCampaignCards(stagger: _stagger),
          ),
        ),
        const _OnboardingTextBlock(
          title: 'Pick any\nbrand campaign',
          subtitle:
              'Browse live campaigns from top Indian brands.\nChoose what fits your audience.',
        ),
      ],
    );
  }
}

class _StackedCampaignCards extends StatelessWidget {
  const _StackedCampaignCards({required this.stagger});

  final Animation<double> stagger;

  static final _cards = [
    (brand: 'boAt',  label: 'Live campaign', amount: '₹50', icon: Icons.headphones,  iconColor: const Color(0xFF6B7280), iconBg: const Color(0xFFF3F4F6)),
    (brand: 'Zepto', label: 'Live campaign', amount: '₹60', icon: Icons.bolt,         iconColor: const Color(0xFFF59E0B), iconBg: const Color(0xFFFEF3C7)),
    (brand: 'CRED',  label: 'Live campaign', amount: '₹45', icon: Icons.credit_card, iconColor: const Color(0xFF6B7280), iconBg: const Color(0xFFF3F4F6)),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(_cards.length, (i) {
          final card = _cards[i];
          final angle = (i - 1) * 0.10;
          final dy = (i - 1) * 18.0;
          final scale = 0.84 + (i == 1 ? 0.16 : i == 0 ? 0.08 : 0.04);

          final anim = CurvedAnimation(
            parent: stagger,
            curve: Interval(i * 0.15, i * 0.15 + 0.55, curve: Curves.easeOut),
          );

          return FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset(0, 0.12 * (i + 1)),
                end: Offset.zero,
              ).animate(anim),
              child: Transform.translate(
                offset: Offset(0, dy),
                child: Transform.rotate(
                  angle: angle,
                  child: Transform.scale(
                    scale: scale,
                    child: _CampaignPreviewCard(
                      brand: card.brand,
                      label: card.label,
                      amount: card.amount,
                      icon: card.icon,
                      iconColor: card.iconColor,
                      iconBg: card.iconBg,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _CampaignPreviewCard extends StatelessWidget {
  const _CampaignPreviewCard({
    required this.brand,
    required this.label,
    required this.amount,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });

  final String brand;
  final String label;
  final String amount;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 272,
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  brand,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF16A34A),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
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
