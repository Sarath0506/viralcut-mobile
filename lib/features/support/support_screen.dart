import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/widgets/vc_scaffold.dart';
import '../../theme/halchal_colors.dart';
import 'support_providers.dart';

const _supportEmail = 'Support@halchalapp.com';

class SupportScreen extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final vc = HalchalColors.of(context);
    final faqs = ref.watch(faqsProvider);

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
                const _ContactInfoTile(
                  icon: Icons.location_on_outlined,
                  title: 'Headquarters',
                  subtitle:
                      'Mutiny Talent Pvt. Ltd.\nHyderabad, Telangana, India',
                ),
                Divider(height: 1, indent: 16, endIndent: 16, color: vc.border),
                _ContactInfoTile(
                  icon: Icons.confirmation_num_outlined,
                  title: 'Raise a Ticket',
                  subtitle: 'Submit a support request and track its status',
                  showChevron: true,
                  onTap: () async => context.push('/support/raise-ticket'),
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
          faqs.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => Text(
              'Couldn\'t load FAQs.',
              style: GoogleFonts.inter(fontSize: 13, color: vc.muted),
            ),
            data: (items) {
              if (items.isEmpty) return const SizedBox.shrink();
              return Container(
                decoration: BoxDecoration(
                  color: vc.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: vc.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      _FaqTile(question: items[i].question, answer: items[i].answer),
                      if (i != items.length - 1)
                        Divider(height: 1, indent: 16, endIndent: 16, color: vc.border),
                    ],
                  ],
                ),
              );
            },
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
    this.showChevron = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Future<void> Function()? onTap;
  final bool showChevron;

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
          if (showChevron) ...[
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: vc.muted, size: 20),
          ],
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
