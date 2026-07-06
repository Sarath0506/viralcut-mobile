import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/widgets/vc_scaffold.dart';
import '../../theme/viralcut_colors.dart';
import 'profile_providers.dart';

const _platforms = [
  (key: 'instagram', label: 'Instagram', icon: Icons.camera_alt_outlined),
  (key: 'youtube', label: 'YouTube', icon: Icons.play_circle_outline_rounded),
  (key: 'twitter', label: 'Twitter / X', icon: Icons.alternate_email_rounded),
  (key: 'linkedin', label: 'LinkedIn', icon: Icons.business_center_outlined),
  (key: 'website', label: 'Website', icon: Icons.link_rounded),
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
  bool _initialized = false;
  bool _saving = false;

  TextEditingController _controllerFor(String key) =>
      _controllers.putIfAbsent(key, () => TextEditingController());

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _initFrom(Map<String, dynamic> user) {
    if (_initialized) return;
    final links = (user['socialLinks'] as Map<String, dynamic>?) ?? {};
    for (final p in _platforms) {
      _controllerFor(p.key).text = links[p.key] as String? ?? '';
    }
    _initialized = true;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final links = <String, String>{
        for (final p in _platforms)
          if (_controllerFor(p.key).text.trim().isNotEmpty)
            p.key: _controllerFor(p.key).text.trim(),
      };
      await ref.read(apiClientProvider).updateProfile(socialLinks: links);
      ref.invalidate(profileMeProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connected accounts updated')),
      );
      context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
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
                'Add links to your public profiles so brands can find your work.',
                style: TextStyle(color: vc.muted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              for (final p in _platforms) ...[
                TextField(
                  controller: _controllerFor(p.key),
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: p.label,
                    hintText: 'https://…',
                    prefixIcon: Icon(p.icon),
                    filled: true,
                    fillColor: vc.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              const SizedBox(height: 10),
              FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save changes'),
              ),
            ],
          );
        },
      ),
    );
  }
}
