import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/layout/app_spacing.dart';
import '../../core/layout/bottom_action_bar.dart';
import '../../core/layout/onboarding_text_block.dart';
import '../../theme/viralcut_colors.dart';
import '../../theme/viralcut_text_styles.dart';
import '../auth/widgets/auth_app_icon.dart';
import '../auth/widgets/auth_ui.dart';

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

  @override
  Widget build(BuildContext context) {
    final vc = ViralCutColors.of(context);
    final primary = Theme.of(context).colorScheme.primary;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            vc.authGradientStart,
            vc.authGradientMid,
            vc.money.withValues(alpha: 0.08),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
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
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Halchal',
                        style: ViralCutTextStyles.sectionTitle(context).copyWith(
                          color: primary,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => context.go('/signup'),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(
                            AppSpacing.minTouchTarget,
                            AppSpacing.minTouchTarget,
                          ),
                        ),
                        child: Text(
                          'Skip',
                          style: ViralCutTextStyles.meta(context).copyWith(
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
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _page = i),
                  children: [
                    _WalletOnboardingSlide(
                      floatAnimation: _floatController,
                    ),
                    const _MarketplaceOnboardingSlide(),
                  ],
                ),
              ),
              BottomActionBar(
                indicator: _PageDots(activeIndex: _page, count: 2),
                primary: AuthPrimaryButton(
                  label: _page == 0 ? 'Get Started' : 'Continue',
                  onPressed: () {
                    if (_page == 0) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                      );
                    } else {
                      context.go('/signup');
                    }
                  },
                ),
                secondary: TextButton(
                  onPressed: () => context.go('/login'),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(
                      AppSpacing.minTouchTarget,
                      AppSpacing.minTouchTarget,
                    ),
                  ),
                  child: RichText(
                    text: TextSpan(
                      style: ViralCutTextStyles.meta(context).copyWith(
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
              ),
            ],
          ),
        ),
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
    final vc = ViralCutColors.of(context);
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

class _WalletOnboardingSlide extends StatelessWidget {
  const _WalletOnboardingSlide({required this.floatAnimation});

  final Animation<double> floatAnimation;

  @override
  Widget build(BuildContext context) {
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
              child: const _PhoneWalletMockup(),
            ),
          ),
        ),
        const OnboardingTextBlock(
          title: 'Post clips. Get paid.',
          subtitle:
              'Turn your short-form content into real earnings with brand campaigns.',
        ),
      ],
    );
  }
}

class _PhoneWalletMockup extends StatelessWidget {
  const _PhoneWalletMockup();

  @override
  Widget build(BuildContext context) {
    final vc = ViralCutColors.of(context);
    final onCard = vc.onPrimary;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          width: 260,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: vc.deepSurface,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: vc.onSurface.withValues(alpha: 0.18),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '9:41',
                    style: GoogleFonts.inter(
                      color: onCard.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.signal_cellular_alt,
                          size: 14, color: onCard.withValues(alpha: 0.7)),
                      const SizedBox(width: 4),
                      Icon(Icons.wifi,
                          size: 14, color: onCard.withValues(alpha: 0.7)),
                      const SizedBox(width: 4),
                      Icon(Icons.battery_full,
                          size: 14, color: onCard.withValues(alpha: 0.7)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  const Spacer(),
                  Icon(Icons.notifications_none,
                      color: onCard.withValues(alpha: 0.8)),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: vc.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CURRENT BALANCE',
                      style: GoogleFonts.inter(
                        color: onCard.withValues(alpha: 0.54),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Rs 35,170',
                      style: GoogleFonts.plusJakartaSans(
                        color: onCard,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '+12% vs last week',
                      style: GoogleFonts.inter(
                        color: vc.moneyBright,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _MockTxRow(
                color: vc.error,
                amount: 'Rs 4,200',
              ),
              const SizedBox(height: 8),
              _MockTxRow(
                color: Theme.of(context).colorScheme.primary,
                amount: 'Rs 8,550',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MockTxRow extends StatelessWidget {
  const _MockTxRow({required this.color, required this.amount});

  final Color color;
  final String amount;

  @override
  Widget build(BuildContext context) {
    final onCard = ViralCutColors.of(context).onPrimary;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.play_arrow, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: onCard.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 6,
                width: 80,
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: onCard.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
        Text(
          amount,
          style: GoogleFonts.inter(
            color: onCard,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _MarketplaceOnboardingSlide extends StatefulWidget {
  const _MarketplaceOnboardingSlide();

  @override
  State<_MarketplaceOnboardingSlide> createState() =>
      _MarketplaceOnboardingSlideState();
}

class _MarketplaceOnboardingSlideState extends State<_MarketplaceOnboardingSlide>
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
    final vc = ViralCutColors.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final cards = [
      _CampaignPreviewData(
        brand: 'boAt',
        category: 'Electronics & Lifestyle',
        metricLabel: 'EARNING POTENTIAL',
        metricValue: 'Rs 5,000+',
        metricColor: vc.moneyBright,
        progress: 0.72,
        progressColor: vc.moneyBright,
        accent: vc.deepSurface,
      ),
      _CampaignPreviewData(
        brand: 'Zepto',
        category: '10-minute delivery',
        metricLabel: 'URGENT TASKS',
        metricValue: '2 Slots Left',
        metricColor: vc.warning,
        progress: 0.22,
        progressColor: vc.warning,
        accent: vc.primaryVariant,
      ),
      _CampaignPreviewData(
        brand: 'CRED',
        category: 'Fintech & Rewards',
        metricLabel: 'PREMIUM TIER',
        metricValue: 'Top 1% Only',
        metricColor: vc.onSurface,
        progress: 0.95,
        progressColor: primary,
        accent: vc.deepSurface,
      ),
    ];

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              itemCount: cards.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md - 4),
              itemBuilder: (context, index) {
                final start = index * 0.15;
                final anim = CurvedAnimation(
                  parent: _stagger,
                  curve: Interval(start, start + 0.55, curve: Curves.easeOut),
                );
                return FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.12),
                      end: Offset.zero,
                    ).animate(anim),
                    child: _CampaignPreviewCard(data: cards[index]),
                  ),
                );
              },
            ),
          ),
        ),
        const OnboardingTextBlock(
          title: 'Pick any brand campaign',
          subtitle:
              'Browse live campaigns from top Indian brands. Choose what fits your audience.',
        ),
      ],
    );
  }
}

class _CampaignPreviewData {
  const _CampaignPreviewData({
    required this.brand,
    required this.category,
    required this.metricLabel,
    required this.metricValue,
    required this.metricColor,
    required this.progress,
    required this.progressColor,
    required this.accent,
  });

  final String brand;
  final String category;
  final String metricLabel;
  final String metricValue;
  final Color metricColor;
  final double progress;
  final Color progressColor;
  final Color accent;
}

class _CampaignPreviewCard extends StatelessWidget {
  const _CampaignPreviewCard({required this.data});

  final _CampaignPreviewData data;

  @override
  Widget build(BuildContext context) {
    final vc = ViralCutColors.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: vc.border),
        boxShadow: [
          BoxShadow(
            color: vc.onSurface.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: data.accent,
                      child: Text(
                        data.brand[0],
                        style: TextStyle(
                          color: vc.onPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.brand,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          data.category,
                          style: GoogleFonts.inter(
                            color: primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  data.metricLabel,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: vc.muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.metricValue,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: data.metricColor,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: data.progress,
                    minHeight: 4,
                    backgroundColor: vc.border,
                    color: data.progressColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: data.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.image_outlined, color: data.accent),
          ),
        ],
      ),
    );
  }
}
