import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import '../../theme/viralcut_colors.dart';
import '../../core/widgets/vc_scaffold.dart';
import 'profile_providers.dart';

const _platforms = [
  (key: 'instagram', label: 'Instagram', icon: Icons.camera_alt_outlined),
  (key: 'youtube', label: 'YouTube', icon: Icons.play_circle_outline_rounded),
  (key: 'twitter', label: 'Twitter / X', icon: Icons.alternate_email_rounded),
];

class ConnectedAccountsScreen extends ConsumerStatefulWidget {
  const ConnectedAccountsScreen({super.key});

  @override
  ConsumerState<ConnectedAccountsScreen> createState() =>
      _ConnectedAccountsScreenState();
}

class _ConnectedAccountsScreenState
    extends ConsumerState<ConnectedAccountsScreen> {
  final _controllers = <String, TextEditingController>{};
  // stats per platform: null = not fetched yet
  final _stats = <String, Map<String, dynamic>?>{};
  final _fetching = <String, bool>{};
  // platforms where connect was triggered and stats are being scraped in background
  final _pending = <String>{};
  bool _initialized = false;

  TextEditingController _controllerFor(String key) =>
      _controllers.putIfAbsent(key, () => TextEditingController());

  @override
  void dispose() {
    for (final c in _controllers.values) c.dispose();
    super.dispose();
  }

  void _initFrom(Map<String, dynamic> user) {
    if (_initialized) return;
    final links = (user['socialLinks'] as Map<String, dynamic>?) ?? {};
    final stats = (user['socialStats'] as Map<String, dynamic>?) ?? {};
    for (final p in _platforms) {
      _controllerFor(p.key).text = links[p.key] as String? ?? '';
      if (stats[p.key] != null) {
        _stats[p.key] = stats[p.key] as Map<String, dynamic>;
      }
    }
    _initialized = true;
  }

  Future<void> _connect(String platform) async {
    final handle = _controllerFor(platform).text.trim();
    if (handle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your username or profile URL first')),
      );
      return;
    }
    setState(() => _fetching[platform] = true);
    try {
      await ref.read(apiClientProvider).fetchSocialStats(platform, handle);
      setState(() => _pending.add(platform));
      ref.invalidate(profileMeProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$platform saved! Fetching your stats in the background — pull to refresh in ~2 minutes.'),
          duration: const Duration(seconds: 5),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _fetching[platform] = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(profileMeProvider);
    final vc = ViralCutColors.of(context);

    return VcScaffold(
      title: 'Connected Accounts',
      showBack: true,
      body: me.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (user) {
          _initFrom(user);
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Add your username or profile URL so brands can find your work.',
                style: TextStyle(color: vc.muted, fontSize: 13),
              ),
              const SizedBox(height: 20),
              for (final p in _platforms) ...[
                _PlatformCard(
                  platform: p.key,
                  label: p.label,
                  icon: p.icon,
                  controller: _controllerFor(p.key),
                  stats: _stats[p.key],
                  fetching: _fetching[p.key] ?? false,
                  pending: _pending.contains(p.key),
                  onConnect: () => _connect(p.key),
                ),
                const SizedBox(height: 16),
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
    required this.platform,
    required this.label,
    required this.icon,
    required this.controller,
    required this.stats,
    required this.fetching,
    required this.pending,
    required this.onConnect,
  });

  final String platform;
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final Map<String, dynamic>? stats;
  final bool fetching;
  final bool pending;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    final vc = ViralCutColors.of(context);
    final hasStats = stats != null && stats!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasStats ? const Color(0xFF7C3AED).withOpacity(0.4) : vc.border,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: vc.muted),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: vc.onSurface,
                      fontSize: 15)),
              const Spacer(),
              if (hasStats)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Connected',
                      style: TextStyle(
                          color: Color(0xFF7C3AED),
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  style: TextStyle(fontSize: 14, color: vc.onSurface),
                  decoration: InputDecoration(
                    hintText: 'username or profile URL',
                    hintStyle: TextStyle(color: vc.muted, fontSize: 13),
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
                  ),
                ),
              ),
              const SizedBox(width: 10),
              fetching
                  ? const SizedBox(
                      width: 80,
                      height: 40,
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : SizedBox(
                      height: 40,
                      width: 90,
                      child: FilledButton(
                        onPressed: onConnect,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Connect',
                            style: TextStyle(fontSize: 13)),
                      ),
                    ),
            ],
          ),
          if (pending && !hasStats) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                SizedBox(
                  width: 14, height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: const Color(0xFF7C3AED).withOpacity(0.7),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Fetching your stats… pull to refresh in ~2 min',
                    style: TextStyle(
                      fontSize: 11,
                      color: const Color(0xFF7C3AED).withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (hasStats) ...[
            const SizedBox(height: 14),
            _StatsRow(stats: stats!, platform: platform),
          ],
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
    final followers = _fmt(stats['followersCount']);
    final posts = _fmt(stats['postsCount']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1),
        const SizedBox(height: 10),
        if (displayName != null)
          Text(displayName,
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: vc.onSurface, fontSize: 13)),
        if (handle.isNotEmpty)
          Text('@$handle',
              style: TextStyle(color: vc.muted, fontSize: 12)),
        const SizedBox(height: 8),
        Row(
          children: [
            _StatChip(label: 'Followers', value: followers),
            const SizedBox(width: 10),
            _StatChip(
                label: platform == 'youtube' ? 'Videos' : 'Posts',
                value: posts),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: vc.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: vc.border),
      ),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF7C3AED))),
          Text(label,
              style: TextStyle(fontSize: 10, color: vc.muted)),
        ],
      ),
    );
  }
}
