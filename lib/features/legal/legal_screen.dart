import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/halchal_colors.dart';

class LegalSection {
  const LegalSection({
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title;
  final String body;
}

class LegalScreen extends StatelessWidget {
  const LegalScreen({
    super.key,
    required this.title,
    required this.lastUpdated,
    required this.sections,
  });

  final String title;
  final String lastUpdated;
  final List<LegalSection> sections;

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
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: vc.onSurface,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Last updated: $lastUpdated',
              style: GoogleFonts.inter(fontSize: 12, color: vc.muted),
            ),
          ),
          // All sections inside one rounded card
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color: vc.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: vc.border),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < sections.length; i++) ...[
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: vc.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(sections[i].icon, size: 18, color: vc.primary),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sections[i].title,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: vc.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  sections[i].body,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    height: 1.55,
                                    color: vc.onSurface.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (i < sections.length - 1)
                      Divider(height: 1, thickness: 0.5, color: vc.border),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Terms & Conditions ──────────────────────────────────────────────────────

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  static const _sections = [
    LegalSection(
      icon: Icons.article_outlined,
      title: '1. Acceptance of Terms',
      body:
          'By accessing and using Halchal and the Halchal creator app, you agree to be bound by these Terms and Conditions. If you do not agree with any part of these terms, you may not use our services. These terms establish a legally binding agreement between you and Mutiny Talent Pvt. Ltd.',
    ),
    LegalSection(
      icon: Icons.work_outline_rounded,
      title: '2. Description of Service',
      body:
          'Mutiny Talent Pvt. Ltd. provides a B2B SaaS platform (Halchal) connecting brands with creators, and a creator-facing mobile app for managing campaigns, content submissions, and payments. We act as the technical intermediary to facilitate these connections securely.',
    ),
    LegalSection(
      icon: Icons.manage_accounts_outlined,
      title: '3. User Accounts',
      body:
          'You are responsible for safeguarding your account credentials. You must notify us immediately of any unauthorized use of your account. Brands and creators are subject to platform verification, and we reserve the right to suspend accounts that violate our community standards.',
    ),
    LegalSection(
      icon: Icons.credit_card_outlined,
      title: '4. Payments and Escrow',
      body:
          'All campaign payments are processed through our secure performance-based payment system. Funds are calculated based on verified views and released to creators upon satisfactory completion of agreed-upon deliverables, as approved by the brand. Halchal charges a platform fee on each successful transaction.',
    ),
    LegalSection(
      icon: Icons.balance_outlined,
      title: '5. Intellectual Property',
      body:
          'Content created during campaigns is subject to the usage rights negotiated within the platform\'s campaign agreement. Halchal retains all rights to the platform infrastructure, code, algorithms, and design. Creators retain ownership of their original content unless otherwise agreed in writing with the brand.',
    ),
    LegalSection(
      icon: Icons.warning_amber_rounded,
      title: '6. Prohibited Activities',
      body:
          'You may not use our platform to engage in fraudulent activity, manipulate view counts, submit plagiarised content, impersonate other users, or violate any applicable Indian laws. Any such violation will result in immediate account suspension and may be reported to relevant authorities.',
    ),
    LegalSection(
      icon: Icons.block_rounded,
      title: '7. Limitation of Liability',
      body:
          'Mutiny Talent Pvt. Ltd. shall not be liable for any indirect, incidental, special, or consequential damages arising from your use of the platform. Our total liability to you for any claims arising under these terms shall not exceed the amount you paid to us in the three months preceding the claim.',
    ),
    LegalSection(
      icon: Icons.loop_rounded,
      title: '8. Termination',
      body:
          'We may suspend or terminate your account at our sole discretion if you breach these terms or engage in conduct that we determine is harmful to the platform or its users. Upon termination, your right to use the platform ceases immediately. Any outstanding payments due to creators will be settled within 30 days.',
    ),
    LegalSection(
      icon: Icons.gavel_rounded,
      title: '9. Governing Law',
      body:
          'These Terms and Conditions are governed by and construed in accordance with the laws of India. Any disputes arising under these terms shall be subject to the exclusive jurisdiction of the courts in Hyderabad, Telangana, India.',
    ),
    LegalSection(
      icon: Icons.mail_outline_rounded,
      title: '10. Contact Us',
      body:
          'If you have any questions about these Terms and Conditions, please contact us at Support@halchalapp.com or write to us at: Mutiny Talent Pvt. Ltd., Hyderabad, Telangana, India.',
    ),
  ];

  @override
  Widget build(BuildContext context) => LegalScreen(
        title: 'Terms & Conditions',
        lastUpdated: 'July 7, 2026',
        sections: _sections,
      );
}

// ── Privacy Policy ───────────────────────────────────────────────────────────

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  static const _sections = [
    LegalSection(
      icon: Icons.visibility_outlined,
      title: '1. Information We Collect',
      body:
          'We collect information you provide directly to us, such as when you create an account, update your profile, participate in campaigns, or request support. This includes your name, email, business details, payment info, and linked social media metrics required for campaign analytics.',
    ),
    LegalSection(
      icon: Icons.share_outlined,
      title: '2. How We Use Your Information',
      body:
          'We use the information we collect to operate and improve our platform, process your transactions, manage escrow payments, accurately connect brands with creators, and communicate with you about platform updates, negotiated rates, and active campaigns.',
    ),
    LegalSection(
      icon: Icons.shield_outlined,
      title: '3. Sharing of Information',
      body:
          'Your public profile information (such as engagement rates and past work) may be shared with potential brand partners on the platform. We never sell your personal data to third parties. Information is only shared with trusted service providers who assist us in operating our platform securely.',
    ),
    LegalSection(
      icon: Icons.lock_outline_rounded,
      title: '4. Data Security',
      body:
          'We implement commercially reasonable technical, administrative, and physical security measures designed to protect your information from loss, theft, misuse, and unauthorized access. All payment data is tokenized and encrypted through our PCI-compliant payment partners.',
    ),
    LegalSection(
      icon: Icons.cookie_outlined,
      title: '5. Cookies & Tracking',
      body:
          'We use cookies and similar tracking technologies to collect and track information about your usage of our services, to improve your experience, and to understand how our platform is used. You may control cookie settings through your browser, but disabling cookies may limit certain features.',
    ),
    LegalSection(
      icon: Icons.shield_outlined,
      title: '6. Your Rights',
      body:
          'You have the right to access, correct, or delete your personal data at any time. You may also request a copy of the data we hold about you or restrict how we process it. To exercise these rights, please contact us at Support@halchalapp.com. We will respond within 30 days.',
    ),
    LegalSection(
      icon: Icons.history_rounded,
      title: '7. Data Retention',
      body:
          'We retain your personal data for as long as your account is active or as needed to provide our services. If you close your account, we will retain and use your information as necessary to comply with legal obligations, resolve disputes, and enforce our agreements.',
    ),
    LegalSection(
      icon: Icons.update_rounded,
      title: '8. Changes to This Policy',
      body:
          'We may update this Privacy Policy from time to time. We will notify you of any significant changes by posting the new policy on this page and updating the \'Last updated\' date. We encourage you to review this policy periodically to stay informed about how we protect your information.',
    ),
    LegalSection(
      icon: Icons.mail_outline_rounded,
      title: '9. Contact Us',
      body:
          'If you have any questions about this Privacy Policy or our data practices, please contact us at Support@halchalapp.com or write to us at: Mutiny Talent Pvt. Ltd., Hyderabad, Telangana, India.',
    ),
  ];

  @override
  Widget build(BuildContext context) => LegalScreen(
        title: 'Privacy Policy',
        lastUpdated: 'July 7, 2026',
        sections: _sections,
      );
}
