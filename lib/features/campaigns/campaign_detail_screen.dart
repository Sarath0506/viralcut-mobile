import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:google_fonts/google_fonts.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/creator_profile/creator_profile_providers.dart';
import '../../core/realtime/campaign_realtime_scope.dart';
import '../../core/layout/app_spacing.dart';
import 'campaign_providers.dart';
import '../../core/widgets/vc_scaffold.dart';
import '../../theme/viralcut_colors.dart';
import '../profile/profile_providers.dart';
import '../profile/widgets/profile_switcher_sheet.dart';
import 'widgets/campaign_detail_body.dart';

class CampaignDetailScreen extends ConsumerWidget {
  const CampaignDetailScreen({super.key, required this.id});

  final String id;

  String _ctaLabel(Participation? participation) {
    if (participation == null) return 'Join campaign';
    switch (participation.summary) {
      case 'joined':
      case 'drafts_incomplete':
        return 'Continue submission';
      case 'in_review':
      case 'action_required':
      case 'proof_complete':
      case 'closed':
        return 'View submission';
      default:
        return 'View submission';
    }
  }

  void _onCta(
    BuildContext context,
    WidgetRef ref,
    Participation? participation,
  ) async {
    if (participation == null) {
      // Guard: require at least one linked social account
      final user = ref.read(profileMeProvider).valueOrNull;
      final socialLinksMap =
          (user?['socialLinks'] as Map<String, dynamic>?) ?? {};
      final hasAnyLinked = ['instagram', 'youtube', 'twitter'].any(
        (k) => ((socialLinksMap[k] as String?) ?? '').isNotEmpty,
      );
      if (!hasAnyLinked) {
        if (!context.mounted) return;
        _showLinkSocialsSheet(context);
        return;
      }

      final activeProfile = ref.read(activeCreatorProfileProvider);
      if (activeProfile == null) {
        await showProfileSwitcherSheet(context);
        return;
      }

      try {
        await ref.read(apiClientProvider).joinCampaign(id, activeProfile.id);
        ref.invalidate(campaignParticipationProvider(id));
        if (!context.mounted) return;
        context.push('/campaigns/$id/submit');
      } on ApiException catch (e) {
        if (e.code == 'ALREADY_JOINED') {
          try {
            final existing = await ref
                .read(apiClientProvider)
                .fetchParticipationByCampaign(id, activeProfile.id);
            ref.invalidate(campaignParticipationProvider(id));
            if (!context.mounted) return;
            context.push('/campaigns/${existing.campaignId}/submit');
            return;
          } on ApiException {
            // Fall through to the original error message.
          }
        }
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
      return;
    }

    if (participation.summary == 'joined' ||
        participation.summary == 'drafts_incomplete') {
      context.push('/campaigns/$id/submit');
      return;
    }

    context.push('/participations/${participation.id}');
  }

  void _showLinkSocialsSheet(BuildContext context) {
    final vc = ViralCutColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: vc.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: vc.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.link_rounded,
                  color: Colors.white, size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              'Link a social account first',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: vc.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You need to connect at least one social account (Instagram, YouTube, or X) before joining a campaign.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: vc.muted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/profile/connected-accounts');
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Connect your socials',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Maybe later',
                  style: GoogleFonts.inter(color: vc.muted),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaign = ref.watch(campaignDetailProvider(id));
    final participation = ref.watch(campaignParticipationProvider(id));
    ref.watch(profileMeProvider); // keep social links fresh
    final vc = ViralCutColors.of(context);

    return campaign.when(
      loading: () => const VcScaffold(
        title: 'Campaign',
        showBack: true,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => VcScaffold(
        title: 'Campaign',
        showBack: true,
        body: Center(child: Text('$e')),
      ),
      data: (c) {
        final p = participation.valueOrNull;
        final cta = _ctaLabel(p);
        final joining = participation.isLoading && p == null;

        return CampaignRealtimeScope(
          campaignId: id,
          child: Scaffold(
            backgroundColor: vc.background,
            appBar: AppBar(
              title: Text(
                c.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              automaticallyImplyLeading: false,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => context.canPop() ? context.pop() : context.go('/campaigns'),
              ),
            ),
            body: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(campaignDetailProvider(id));
                ref.invalidate(campaignParticipationProvider(id));
                await ref.read(campaignDetailProvider(id).future);
              },
              child: CampaignDetailBody(campaign: c, participation: p),
            ),
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: AppSpacing.bottomActionPadding(context),
                child: FilledButton(
                  onPressed: joining ? null : () => _onCta(context, ref, p),
                  child: Text(joining ? 'Loading…' : cta),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
