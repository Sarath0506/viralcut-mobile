import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/creator_profile/creator_profile_providers.dart';
import '../../core/widgets/social_logo_painters.dart';
import '../../theme/viralcut_colors.dart';
import '../../core/widgets/vc_scaffold.dart';

const _platforms = [
  _PlatformMeta(
    key: 'instagram',
    label: 'Instagram',
    hint: '@username or profile URL',
  ),
  _PlatformMeta(
    key: 'youtube',
    label: 'YouTube',
    hint: 'Channel name or URL',
  ),
  _PlatformMeta(
    key: 'twitter',
    label: 'Twitter / X',
    hint: '@handle or profile URL',
  ),
];

class _PlatformMeta {
  const _PlatformMeta({
    required this.key,
    required this.label,
    required this.hint,
  });
  final String key;
  final String label;
  final String hint;
}

class ConnectedAccountsScreen extends ConsumerStatefulWidget {
  const ConnectedAccountsScreen({super.key});

  @override
  ConsumerState<ConnectedAccountsScreen> createState() =>
      _ConnectedAccountsScreenState();
}

class _ConnectedAccountsScreenState
    extends ConsumerState<ConnectedAccountsScreen> {
  final _controllers = <String, TextEditingController>{};
  final _stats = <String, Map<String, dynamic>?>{};
  final _connecting = <String, bool>{};
  final _disconnecting = <String, bool>{};
  final _pending = <String>{};
  bool _initialized = false;

  TextEditingController _ctrl(String key) =>
      _controllers.putIfAbsent(key, () => TextEditingController());

  @override
  void dispose() {
    for (final c in _controllers.values) { c.dispose(); }
    super.dispose();
  }

  String? _lastProfileId;

  void _initFrom(Map<String, dynamic> socialLinks, Map<String, dynamic> socialStats) {
    if (_initialized) return;
    for (final p in _platforms) {
      _ctrl(p.key).text = socialLinks[p.key] as String? ?? '';
      if (socialStats[p.key] != null) {
        _stats[p.key] = socialStats[p.key] as Map<String, dynamic>;
      }
    }
    _initialized = true;
  }

  bool _isConnected(String platform) =>
      _ctrl(platform).text.trim().isNotEmpty;

  Future<void> _connect(String platform, String profileId) async {
    final handle = _ctrl(platform).text.trim();
    if (handle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your username or profile URL first')),
      );
      return;
    }
    setState(() => _connecting[platform] = true);
    try {
      await ref.read(apiClientProvider).connectProfileSocial(profileId, platform, handle);
      _initialized = false;
      setState(() => _pending.add(platform));
      ref.invalidate(creatorProfilesProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$platform connected! Stats load in ~2 min.'),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connection failed. Check your username and try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _connecting[platform] = false);
    }
  }

  Future<void> _disconnect(String platform, String profileId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final vc = ViralCutColors.of(ctx);
        return AlertDialog(
          backgroundColor: vc.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18)),
          title: Text(
            'Disconnect ${_platforms.firstWhere((p) => p.key == platform).label}?',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700, color: vc.onSurface),
          ),
          content: Text(
            'Your stats and handle will be removed. You can reconnect anytime.',
            style: GoogleFonts.inter(fontSize: 13, color: vc.muted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: TextStyle(color: vc.muted)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Disconnect',
                  style: TextStyle(color: vc.error, fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    setState(() => _disconnecting[platform] = true);
    try {
      await ref.read(apiClientProvider).disconnectProfileSocial(profileId, platform);
      setState(() {
        _ctrl(platform).text = '';
        _stats.remove(platform);
        _pending.remove(platform);
        _initialized = false;
      });
      ref.invalidate(creatorProfilesProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$platform disconnected'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _disconnecting[platform] = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profiles = ref.watch(creatorProfilesProvider);
    final activeProfile = ref.watch(activeCreatorProfileProvider);
    final vc = ViralCutColors.of(context);

    // Reset init when the active profile changes
    if (activeProfile?.id != _lastProfileId) {
      _initialized = false;
      _lastProfileId = activeProfile?.id;
      for (final c in _controllers.values) { c.clear(); }
      _stats.clear();
      _pending.clear();
    }

    return VcScaffold(
      title: 'Connected Accounts',
      showBack: true,
      body: profiles.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (_) {
          if (activeProfile == null) {
            return Center(
              child: Text(
                'No profile selected',
                style: GoogleFonts.inter(color: vc.muted),
              ),
            );
          }

          final links = activeProfile.socialLinks;
          final stats = activeProfile.socialStats;
          _initFrom(links, stats);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF7C3AED)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '"${activeProfile.displayName}" — switch profiles to manage connections for other accounts.',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: const Color(0xFF7C3AED), height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Link your accounts so brands can match you with the right campaigns.',
                style: GoogleFonts.inter(fontSize: 13, color: vc.muted, height: 1.45),
              ),
              const SizedBox(height: 20),
              for (final p in _platforms) ...[
                _PlatformCard(
                  meta: p,
                  controller: _ctrl(p.key),
                  stats: _stats[p.key],
                  isConnected: _isConnected(p.key),
                  isConnecting: _connecting[p.key] ?? false,
                  isDisconnecting: _disconnecting[p.key] ?? false,
                  isPending: _pending.contains(p.key),
                  onConnect: () => _connect(p.key, activeProfile.id),
                  onDisconnect: () => _disconnect(p.key, activeProfile.id),
                ),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _PlatformCard extends StatelessWidget {
  const _PlatformCard({
    required this.meta,
    required this.controller,
    required this.stats,
    required this.isConnected,
    required this.isConnecting,
    required this.isDisconnecting,
    required this.isPending,
    required this.onConnect,
    required this.onDisconnect,
  });

  final _PlatformMeta meta;
  final TextEditingController controller;
  final Map<String, dynamic>? stats;
  final bool isConnected;
  final bool isConnecting;
  final bool isDisconnecting;
  final bool isPending;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  bool get _hasStats => stats != null && stats!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final vc = ViralCutColors.of(context);

    return Container(
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isConnected
              ? const Color(0xFF22C55E).withValues(alpha: 0.35)
              : vc.border,
        ),
      ),
      child: Column(
        children: [
          // ── Header row ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(
              children: [
                // Real logo
                SocialLogoBox(platform: meta.key, size: 42),
                const SizedBox(width: 12),
                // Platform name + status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meta.label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: vc.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (isConnected)
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Color(0xFF22C55E),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isPending ? 'Syncing stats…' : 'Connected',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: isPending
                                    ? vc.muted
                                    : const Color(0xFF22C55E),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          'Not connected',
                          style: GoogleFonts.inter(
                              fontSize: 11, color: vc.muted),
                        ),
                    ],
                  ),
                ),
                // Disconnect button (only when connected)
                if (isConnected)
                  isDisconnecting
                      ? const SizedBox(
                          width: 36,
                          height: 36,
                          child: Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFFEF4444)),
                            ),
                          ),
                        )
                      : IconButton(
                          onPressed: onDisconnect,
                          icon: const Icon(Icons.link_off_rounded,
                              size: 20, color: Color(0xFFEF4444)),
                          tooltip: 'Disconnect',
                        ),
              ],
            ),
          ),

          // ── Stats (when connected + loaded) ──
          if (_hasStats) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: _StatsRow(stats: stats!, platform: meta.key),
            ),
          ],

          // ── Pending notice ──
          if (isPending && !_hasStats)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: vc.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 13,
                      height: 13,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.8, color: vc.muted),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Fetching your stats — pull to refresh in ~2 min',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: vc.muted),
                    ),
                  ],
                ),
              ),
            ),

          // ── Input row (always show when not connected) ──
          if (!isConnected)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      keyboardType: TextInputType.url,
                      autocorrect: false,
                      style: GoogleFonts.inter(
                          fontSize: 13, color: vc.onSurface),
                      decoration: InputDecoration(
                        hintText: meta.hint,
                        hintStyle: GoogleFonts.inter(
                            color: vc.muted, fontSize: 12),
                        filled: true,
                        fillColor: vc.background,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: vc.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: vc.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: Color(0xFF7C3AED), width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  isConnecting
                      ? const SizedBox(
                          width: 80,
                          height: 40,
                          child: Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF7C3AED)),
                            ),
                          ),
                        )
                      : SizedBox(
                          height: 40,
                          width: 80,
                          child: FilledButton(
                            onPressed: onConnect,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF7C3AED),
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(10)),
                            ),
                            child: Text('Connect',
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ),
                ],
              ),
            ),

          const SizedBox(height: 14),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats, required this.platform});

  final Map<String, dynamic> stats;
  final String platform;

  String _fmt(dynamic val) {
    final n = (val as num?)?.toInt() ?? 0;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    final vc = ViralCutColors.of(context);
    final handle = stats['handle'] as String? ?? '';
    final displayName = stats['displayName'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (displayName != null || handle.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                if (displayName != null)
                  Text(
                    displayName,
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: vc.onSurface,
                        fontSize: 12),
                  ),
                if (displayName != null && handle.isNotEmpty)
                  Text(' · ',
                      style: TextStyle(color: vc.muted, fontSize: 12)),
                if (handle.isNotEmpty)
                  Text('@$handle',
                      style:
                          GoogleFonts.inter(color: vc.muted, fontSize: 12)),
              ],
            ),
          ),
        Row(
          children: [
            _StatChip(
                label: 'Followers',
                value: _fmt(stats['followersCount'])),
            const SizedBox(width: 8),
            _StatChip(
                label: platform == 'youtube' ? 'Videos' : 'Posts',
                value: _fmt(stats['postsCount'])),
          ],
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final vc = ViralCutColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: vc.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: vc.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: const Color(0xFF7C3AED),
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 10, color: vc.muted),
          ),
        ],
      ),
    );
  }
}
