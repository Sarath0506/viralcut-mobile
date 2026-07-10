import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api/api_base_url.dart';
import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/creator_profile/creator_profile_providers.dart';
import '../../core/format/money_format.dart';
import '../../core/layout/app_spacing.dart';
import '../../core/layout/list_entrance.dart';
import '../dashboard/widgets/social_connect_section.dart';
import 'profile_providers.dart';
import 'widgets/profile_switcher_sheet.dart';
import '../../theme/halchal_colors.dart';
import '../../theme/theme_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _uploadingAvatar = false;

  String _initialsFor(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Future<void> _pickAndUploadAvatar() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (file == null) return;

    setState(() => _uploadingAvatar = true);
    try {
      final ext = file.name.split('.').last.toLowerCase();
      final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
      await ref.read(apiClientProvider).uploadAvatar(
            filePath: file.path,
            fileName: file.name,
            mimeType: mime,
          );
      ref.invalidate(profileMeProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to verify your phone again to sign in.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await ref.read(authStateProvider.notifier).logout();
    ref.invalidate(profileMeProvider);
    ref.invalidate(profileDashboardProvider);
    ref.invalidate(profileActiveSubmissionsProvider);

    if (context.mounted) context.go('/login');
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final step1 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This is permanent. Your profile, earnings history, and KYC documents will be erased and cannot be recovered.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, delete my account'),
          ),
        ],
      ),
    );
    if (step1 != true || !context.mounted) return;

    final controller = TextEditingController();
    final step2 = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Are you absolutely sure?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Type DELETE to confirm:'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'DELETE',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: controller.text.trim() == 'DELETE'
                  ? () => Navigator.pop(ctx, true)
                  : null,
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete forever'),
            ),
          ],
        ),
      ),
    );
    // Defer dispose — the dialog closing animation is still running on this frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
    if (step2 != true || !context.mounted) return;

    try {
      await ref.read(authStateProvider.notifier).deleteAccount();
      if (context.mounted) context.go('/login');
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(profileMeProvider);
    final dash = ref.watch(profileDashboardProvider);
    final activeCount = ref.watch(profileActiveSubmissionsProvider);
    final themeMode = ref.watch(themeModeProvider);
    final activeProfile = ref.watch(activeCreatorProfileProvider);
    final vc = HalchalColors.of(context);

    return me.when(
      skipLoadingOnRefresh: true,
      loading: () => const ScreenLoader(),
      error: (e, _) => _ProfileError(
        error: e,
        onRetry: () => ref.invalidate(profileMeProvider),
        onLogout: () => _logout(context, ref),
      ),
      data: (user) {
        final displayName = user['displayName'] as String? ?? 'Creator';
        final avatarUrl = user['avatarUrl'] as String?;
        final username = user['username'] as String?;
        final phone = user['phone'] as String? ?? '';
        final kycStatus = user['kycStatus'] as String? ?? 'pending';
        final isVerified = kycStatus == 'verified';
        final lifetimePaise = dash.valueOrNull?.wallet.lifetimePaise ?? 0;
        final clipsUnderReview = dash.valueOrNull?.clipsUnderReview ?? 0;
        final activeSubmissions = activeCount.valueOrNull ?? 0;
        final profileLinksMap = activeProfile?.socialLinks ?? {};
        final socialLinks = SocialLinks(
          instagram: ((profileLinksMap['instagram'] as String?) ?? '').isNotEmpty,
          youtube: ((profileLinksMap['youtube'] as String?) ?? '').isNotEmpty,
          twitter: ((profileLinksMap['twitter'] as String?) ?? '').isNotEmpty,
        );
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(profileMeProvider);
            ref.invalidate(profileDashboardProvider);
            ref.invalidate(profileActiveSubmissionsProvider);
            ref.invalidate(creatorProfilesProvider);
          },
          child: ScreenStaggeredColumn(
            animationKey: 'profile',
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenHorizontal,
              8,
              AppSpacing.screenHorizontal,
              AppSpacing.floatingNavBottom(context),
            ),
            children: [
              _ProfileHeroCard(
                displayName: displayName,
                avatarUrl: avatarUrl,
                username: username,
                phone: phone,
                isVerified: isVerified,
                initials: _initialsFor(displayName),
                lifetimePaise: lifetimePaise,
                lifetimeLoading: dash.isLoading,
                activeSubmissions: activeSubmissions,
                activeLoading: activeCount.isLoading,
                clipsUnderReview: clipsUnderReview,
                isUploadingAvatar: _uploadingAvatar,
                onAvatarTap: _uploadingAvatar ? null : _pickAndUploadAvatar,
              ),
              const SizedBox(height: 16),
              SocialConnectSection(
                links: socialLinks,
                onInstagramTap: () => context.push('/profile/connected-accounts'),
                onYouTubeTap: () => context.push('/profile/connected-accounts'),
                onXTap: () => context.push('/profile/connected-accounts'),
              ),
              const SizedBox(height: 16),
              const _SectionLabel('ACCOUNT'),
              const SizedBox(height: 8),
              _SettingsGroup(
                rows: [
                  _SettingsRow(
                    icon: Icons.person_outline_rounded,
                    iconColor: vc.primary,
                    label: 'Edit profile',
                    onTap: () => context.push('/profile/edit'),
                  ),
                  _SettingsRow(
                    icon: Icons.link_rounded,
                    iconColor: vc.primary,
                    label: 'Connected accounts',
                    onTap: () => context.push('/profile/connected-accounts'),
                  ),
                  _SettingsRow(
                    icon: Icons.switch_account_outlined,
                    iconColor: vc.primary,
                    label: 'Linked profiles',
                    onTap: () => showProfileSwitcherSheet(context),
                  ),
                  _SettingsRow(
                    icon: Icons.verified_user_outlined,
                    iconColor: isVerified ? vc.moneyBright : vc.warning,
                    label: 'KYC status',
                    badge: kycStatus.toUpperCase(),
                    badgeColor: isVerified ? vc.moneyBright : vc.warning,
                    onTap: () => context.push('/profile/kyc'),
                  ),
                  _SettingsRow(
                    icon: Icons.account_balance_outlined,
                    iconColor: vc.primary,
                    label: 'Bank details',
                    onTap: () => context.push('/wallet/bank-details'),
                  ),
                  _SettingsRow(
                    icon: Icons.payment_outlined,
                    iconColor: vc.primary,
                    label: 'Payout methods',
                    onTap: () => context.push('/wallet/payout-methods'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const _SectionLabel('PREFERENCES'),
              const SizedBox(height: 8),
              _SettingsGroup(
                rows: [
                  _SettingsRow(
                    icon: Icons.notifications_outlined,
                    iconColor: vc.primary,
                    label: 'Notifications',
                    onTap: () => context.push('/notifications'),
                  ),
                  _SettingsRow(
                    icon: Icons.dark_mode_outlined,
                    iconColor: vc.primary,
                    label: 'Dark mode',
                    trailing: Switch(
                      value: themeMode == ThemeMode.dark,
                      onChanged: (_) =>
                          ref.read(themeModeProvider.notifier).toggle(),
                    ),
                    onTap: () => ref.read(themeModeProvider.notifier).toggle(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const _SectionLabel('SUPPORT'),
              const SizedBox(height: 8),
              _SettingsGroup(
                rows: [
                  _SettingsRow(
                    icon: Icons.help_outline_rounded,
                    iconColor: vc.primary,
                    label: 'Support center',
                    onTap: () => context.push('/support'),
                  ),
                  _SettingsRow(
                    icon: Icons.description_outlined,
                    iconColor: vc.primary,
                    label: 'Terms & Conditions',
                    onTap: () => context.push('/legal/terms'),
                  ),
                  _SettingsRow(
                    icon: Icons.privacy_tip_outlined,
                    iconColor: vc.primary,
                    label: 'Privacy Policy',
                    onTap: () => context.push('/legal/privacy'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const _SectionLabel('DANGER ZONE'),
              const SizedBox(height: 8),
              _SettingsGroup(
                rows: [
                  _SettingsRow(
                    icon: Icons.delete_forever_rounded,
                    iconColor: Colors.red,
                    label: 'Delete account',
                    onTap: () => _deleteAccount(context, ref),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _LogoutButton(
                onPressed: () => _logout(context, ref),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileError extends StatelessWidget {
  const _ProfileError({
    required this.error,
    required this.onRetry,
    required this.onLogout,
  });

  final Object error;
  final VoidCallback onRetry;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              error is ApiException
                  ? (error as ApiException).message
                  : '$error',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'API: $kApiBaseUrl\n'
              'On a physical phone use your PC LAN IP:\n'
              'flutter run --dart-define=API_BASE_URL=http://192.168.x.x:3001',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
            const SizedBox(height: 24),
            _LogoutButton(onPressed: onLogout),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.displayName,
    required this.avatarUrl,
    required this.username,
    required this.phone,
    required this.isVerified,
    required this.initials,
    required this.lifetimePaise,
    required this.lifetimeLoading,
    required this.activeSubmissions,
    required this.activeLoading,
    required this.clipsUnderReview,
    required this.isUploadingAvatar,
    required this.onAvatarTap,
  });

  final String displayName;
  final String? avatarUrl;
  final String? username;
  final String phone;
  final bool isVerified;
  final String initials;
  final int lifetimePaise;
  final bool lifetimeLoading;
  final int activeSubmissions;
  final bool activeLoading;
  final int clipsUnderReview;
  final bool isUploadingAvatar;
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final vc = HalchalColors.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final handle = (username != null && username!.isNotEmpty) ? '@$username' : phone;

    return Container(
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: vc.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Gradient accent stripe
          Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [vc.authGradientStart, vc.authGradientMid, vc.authGradientEnd],
              ),
            ),
          ),
          // Avatar + info row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Row(
              children: [
                // Avatar
                GestureDetector(
                  onTap: onAvatarTap,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: primary.withValues(alpha: 0.12),
                        backgroundImage: avatarUrl != null
                            ? CachedNetworkImageProvider(avatarUrl!)
                            : null,
                        child: avatarUrl == null
                            ? Text(
                                initials,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: primary,
                                ),
                              )
                            : null,
                      ),
                      if (isUploadingAvatar)
                        const CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.black45,
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          ),
                        ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: vc.surface, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt_rounded,
                              size: 11, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                // Name + handle + badges
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: vc.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        handle,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: vc.muted),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (isVerified)
                            _Badge(
                              label: 'Verified',
                              icon: Icons.verified_rounded,
                              color: vc.moneyBright,
                            )
                          else
                            _Badge(
                              label: 'Unverified',
                              icon: Icons.shield_outlined,
                              color: vc.muted,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Stats row
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: vc.border)),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _StatCell(
                      value: lifetimeLoading ? null : formatPaise(lifetimePaise),
                      label: 'Total earned',
                      valueColor: vc.money,
                    ),
                  ),
                  VerticalDivider(color: vc.border, width: 1),
                  Expanded(
                    child: _StatCell(
                      value: activeLoading ? null : '$activeSubmissions',
                      label: 'Active clips',
                      valueColor: vc.onSurface,
                    ),
                  ),
                  VerticalDivider(color: vc.border, width: 1),
                  Expanded(
                    child: _StatCell(
                      value: '$clipsUnderReview',
                      label: 'In review',
                      valueColor: primary,
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

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.icon, required this.color});

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.value,
    required this.label,
    required this.valueColor,
  });

  final String? value;
  final String label;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final vc = HalchalColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          value == null
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: valueColor.withValues(alpha: 0.5),
                  ),
                )
              : Text(
                  value!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: valueColor,
                  ),
                ),
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: vc.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final vc = HalchalColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: vc.muted,
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.rows});

  final List<_SettingsRow> rows;

  @override
  Widget build(BuildContext context) {
    final vc = HalchalColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: vc.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i != rows.length - 1)
              Divider(height: 1, indent: 56, color: vc.border),
          ],
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.badge,
    this.badgeColor,
    this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String? badge;
  final Color? badgeColor;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final vc = HalchalColors.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 17, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: vc.onSurface,
                ),
              ),
            ),
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (badgeColor ?? vc.warning).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge!,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: badgeColor ?? vc.warning,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            trailing ?? Icon(Icons.chevron_right_rounded, color: vc.muted),
          ],
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final vc = HalchalColors.of(context);
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(Icons.logout, color: vc.error),
        label: Text(
          'Log out',
          style: TextStyle(
            color: vc.error,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: vc.infoSurface,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
