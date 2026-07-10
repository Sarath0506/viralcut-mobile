import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/widgets/vc_scaffold.dart';
import '../../theme/halchal_colors.dart';

const _supportEmail = 'Support@halchalapp.com';

const _faqs = <({String question, String answer})>[
  (
    question: 'When do I get paid for my views?',
    answer:
        'Once your live post is approved, view counts refresh periodically and your earnings move to "Pending" first. They become withdrawable once the brand\'s review window closes for that submission.',
  ),
  (
    question: 'Why was my draft or live proof rejected?',
    answer:
        'Check the rejection reason on the submission\'s details page — it\'s left by the brand reviewer. Common causes are missing the product, not following the content brief, or a private/unreachable post link.',
  ),
  (
    question: 'How long does KYC verification take?',
    answer:
        'Most KYC submissions are reviewed within 1-2 business days. You\'ll get a notification the moment it\'s approved or if we need a clearer document.',
  ),
  (
    question: 'Why do I need to add bank details before withdrawing?',
    answer:
        'We need your account holder name, account number (or UPI ID), and IFSC code to actually send the payout to the right place. This is a one-time setup — after that, withdrawals just need an amount.',
  ),
  (
    question: 'Can I use the same login on two accounts?',
    answer:
        'No — each account is tied to one phone number and there\'s no account-switcher today. If you manage more than one creator profile, sign up with a separate phone number for each and log out/in to switch.',
  ),
  (
    question: 'A campaign I joined got paused — what happens to my submission?',
    answer:
        'Nothing is lost. Pausing is temporary and only stops new submissions; your existing drafts, reviews, and live proof keep whatever stage they were already in.',
  ),
];

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  Future<void> _emailSupport() async {
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      query: 'subject=${Uri.encodeComponent('Support request')}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final vc = HalchalColors.of(context);

    return VcScaffold(
      title: 'Support Center',
      showBack: true,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 4),
          Text(
            'CONTACT US',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: vc.muted,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: vc.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: vc.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _ContactInfoTile(
                  icon: Icons.mail_outline_rounded,
                  title: 'Email Us',
                  subtitle: _supportEmail,
                  onTap: _emailSupport,
                ),
                Divider(height: 1, indent: 16, endIndent: 16, color: vc.border),
                _ContactInfoTile(
                  icon: Icons.location_on_outlined,
                  title: 'Headquarters',
                  subtitle: 'Mutiny Talent Pvt. Ltd.\nHyderabad, Telangana, India',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'FREQUENTLY ASKED',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: vc.muted,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: vc.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: vc.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < _faqs.length; i++) ...[
                  _FaqTile(question: _faqs[i].question, answer: _faqs[i].answer),
                  if (i != _faqs.length - 1)
                    Divider(height: 1, indent: 16, endIndent: 16, color: vc.border),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactInfoTile extends StatelessWidget {
  const _ContactInfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Future<void> Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final vc = HalchalColors.of(context);
    final tile = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFFF59E0B)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: vc.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: vc.muted,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return tile;
    return InkWell(
      onTap: onTap,
      child: tile,
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    final vc = HalchalColors.of(context);
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedAlignment: Alignment.topLeft,
        iconColor: vc.primary,
        collapsedIconColor: vc.muted,
        title: Text(
          question,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: vc.onSurface,
          ),
        ),
        children: [
          Text(
            answer,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: vc.muted,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
