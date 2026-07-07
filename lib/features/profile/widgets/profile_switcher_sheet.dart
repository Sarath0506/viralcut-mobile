import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/api/api_client.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/creator_profile/creator_profile.dart';
import '../../../core/creator_profile/creator_profile_providers.dart';
import '../../../theme/halchal_colors.dart';

const _platforms = <({String key, String label, IconData icon})>[
  (key: 'instagram', label: 'Instagram', icon: Icons.camera_alt_rounded),
  (key: 'youtube', label: 'YouTube', icon: Icons.play_circle_fill_rounded),
  (key: 'twitter', label: 'X (Twitter)', icon: Icons.tag_rounded),
  (key: 'tiktok', label: 'TikTok', icon: Icons.music_note_rounded),
];

IconData _iconForPlatform(String platform) {
  return _platforms
      .firstWhere(
        (p) => p.key == platform,
        orElse: () => _platforms.first,
      )
      .icon;
}

Future<void> showProfileSwitcherSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const ProfileSwitcherSheet(),
  );
}

class ProfileSwitcherSheet extends ConsumerStatefulWidget {
  const ProfileSwitcherSheet({super.key});

  @override
  ConsumerState<ProfileSwitcherSheet> createState() => _ProfileSwitcherSheetState();
}

class _ProfileSwitcherSheetState extends ConsumerState<ProfileSwitcherSheet> {
  bool _showAddForm = false;

  @override
  Widget build(BuildContext context) {
    final vc = HalchalColors.of(context);
    final profiles = ref.watch(creatorProfilesProvider);
    final activeId = ref.watch(activeCreatorProfileProvider)?.id;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        decoration: BoxDecoration(
          color: vc.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: vc.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _showAddForm ? 'Link a new profile' : 'Switch profile',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: vc.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _showAddForm
                    ? 'Add another social handle to submit content under'
                    : 'Content you submit will be attributed to the active profile',
                style: GoogleFonts.inter(fontSize: 12.5, color: vc.muted),
              ),
              const SizedBox(height: 16),
              if (_showAddForm)
                _AddProfileForm(
                  onDone: () => setState(() => _showAddForm = false),
                  onCancel: () => setState(() => _showAddForm = false),
                )
              else ...[
                profiles.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text('$e', style: TextStyle(color: vc.muted)),
                  ),
                  data: (list) => Column(
                    children: list
                        .map((p) => _ProfileTile(
                              profile: p,
                              isActive: p.id == activeId,
                              onTap: () async {
                                await ref
                                    .read(activeCreatorProfileIdProvider.notifier)
                                    .setActive(p.id);
                                if (context.mounted) Navigator.pop(context);
                              },
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => setState(() => _showAddForm = true),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add profile'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileTile extends ConsumerWidget {
  const _ProfileTile({
    required this.profile,
    required this.isActive,
    required this.onTap,
  });

  final CreatorProfile profile;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vc = HalchalColors.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isActive ? vc.primary.withValues(alpha: 0.08) : vc.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isActive ? vc.primary : vc.border,
                width: isActive ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: vc.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(_iconForPlatform(profile.platform), size: 18, color: vc.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              profile.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: vc.onSurface,
                              ),
                            ),
                          ),
                          if (profile.isDefault) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: vc.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'DEFAULT',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: vc.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        '@${profile.handle}',
                        style: GoogleFonts.inter(fontSize: 12, color: vc.muted),
                      ),
                    ],
                  ),
                ),
                if (isActive)
                  Icon(Icons.check_circle_rounded, color: vc.primary, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddProfileForm extends ConsumerStatefulWidget {
  const _AddProfileForm({required this.onDone, required this.onCancel});

  final VoidCallback onDone;
  final VoidCallback onCancel;

  @override
  ConsumerState<_AddProfileForm> createState() => _AddProfileFormState();
}

class _AddProfileFormState extends ConsumerState<_AddProfileForm> {
  final _formKey = GlobalKey<FormState>();
  String _platform = _platforms.first.key;
  final _handleController = TextEditingController();
  final _labelController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _handleController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await ref.read(apiClientProvider).createCreatorProfile(
            platform: _platform,
            handle: _handleController.text.trim().replaceFirst('@', ''),
            label: _labelController.text.trim(),
          );
      ref.invalidate(creatorProfilesProvider);
      if (mounted) widget.onDone();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vc = HalchalColors.of(context);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _platforms.map((p) {
              final selected = _platform == p.key;
              return ChoiceChip(
                avatar: Icon(p.icon, size: 16),
                label: Text(p.label),
                selected: selected,
                onSelected: (_) => setState(() => _platform = p.key),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _handleController,
            decoration: InputDecoration(
              labelText: 'Handle',
              hintText: '@yourhandle',
              filled: true,
              fillColor: vc.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (v) =>
                (v == null || v.trim().replaceFirst('@', '').isEmpty)
                    ? 'Enter a handle'
                    : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _labelController,
            decoration: InputDecoration(
              labelText: 'Nickname (optional)',
              hintText: 'e.g. Meme page',
              filled: true,
              fillColor: vc.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Add profile'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
