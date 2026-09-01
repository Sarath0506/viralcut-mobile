import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:google_fonts/google_fonts.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/creator_profile/creator_profile_providers.dart';
import '../../core/realtime/campaign_realtime_scope.dart';
import '../../core/format/money_format.dart';
import '../../core/layout/app_spacing.dart';
import 'campaign_providers.dart';
import '../../core/widgets/primary_action_button.dart';
import '../../core/widgets/vc_scaffold.dart';
import '../../theme/halchal_colors.dart';
import '../profile/profile_providers.dart';
import '../profile/widgets/profile_switcher_sheet.dart';
import 'widgets/campaign_detail_body.dart';

class CampaignDetailScreen extends ConsumerWidget {
  const CampaignDetailScreen({super.key, required this.id});

  final String id;

  String _ctaLabel(Participation? participation) {
    if (participation == null) return 'Apply for this campaign';
    switch (participation.summary) {
      case 'joined':
      case 'drafts_incomplete':
        return 'Submit content';
      default:
        return 'View submission';
    }
  }

  String? _ctaSubtitle(Participation? participation, Campaign c) {
    if (participation != null) return null;
    return 'Start creating & earn up to ${formatPaise(c.maxPayoutPaise)}';
  }

  IconData _ctaIcon(Participation? participation) {
    if (participation == null) return Icons.rocket_launch_rounded;
    switch (participation.summary) {
      case 'joined':
      case 'drafts_incomplete':
        return Icons.send_rounded;
      default:
        return Icons.visibility_rounded;
    }
  }

  void _onCta(
    BuildContext context,
    WidgetRef ref,
    Participation? participation,
  ) async {
    if (participation == null) {
      // Guard: require at least one linked social account on the active profile
      final activeProfileForCheck = ref.read(activeCreatorProfileProvider);
      final profileLinksMap = activeProfileForCheck?.socialLinks ?? {};
      final hasAnyLinked = ['instagram', 'youtube', 'twitter'].any(
        (k) => ((profileLinksMap[k] as String?) ?? '').isNotEmpty,
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
    final vc = HalchalColors.of(context);
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
    final vc = HalchalColors.of(context);

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
                child: (p == null && c.intakeClosed)
                    ? _IntakeClosedNotice(vc: vc, poolPercent: c.poolPercent)
                    : PrimaryActionButton(
                        icon: _ctaIcon(p),
                        label: joining ? 'Loading…' : cta,
                        subtitle: joining ? null : _ctaSubtitle(p, c),
                        loading: joining,
                        vc: vc,
                        onPressed: () => _onCta(context, ref, p),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Shown in place of the "Apply" CTA once a campaign's budget pool has
/// crossed its intake threshold — the backend would reject a join attempt
/// at this point anyway, so this avoids showing an actionable-looking
/// button that always fails.
class _IntakeClosedNotice extends StatelessWidget {
  const _IntakeClosedNotice({required this.vc, required this.poolPercent});

  final HalchalColors vc;
  final int poolPercent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            vc.warning.withValues(alpha: 0.22),
            vc.warning.withValues(alpha: 0.06),
          ],
        ),
        border: Border.all(color: vc.warning.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: vc.warning.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: vc.warning,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: vc.warning.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.lock_clock_rounded, color: Colors.white, size: 19),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Slots filled',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: vc.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: vc.warning.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$poolPercent% full',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: vc.warning,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  "Budget pool is nearly spent — new clippers aren't being accepted right now.",
                  style: GoogleFonts.inter(fontSize: 12, color: vc.muted, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
