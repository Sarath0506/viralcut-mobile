import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/update/app_version_provider.dart';
import '../../../theme/halchal_colors.dart';

class UpdateBanner extends ConsumerWidget {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final update = ref.watch(updateAvailableProvider).valueOrNull;
    if (update == null) return const SizedBox.shrink();

    final vc = HalchalColors.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: vc.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: vc.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.system_update_rounded, color: vc.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Update available',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: vc.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Version ${update.latestVersion} is ready to install',
                  style: GoogleFonts.inter(fontSize: 11, color: vc.muted),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: update.storeUrl == null
                ? null
                : () => launchUrl(
                      Uri.parse(update.storeUrl!),
                      mode: LaunchMode.externalApplication,
                    ),
            child: const Text('Update'),
          ),
          IconButton(
            onPressed: () => ref
                .read(dismissedUpdateVersionProvider.notifier)
                .dismiss(update.latestVersion),
            icon: Icon(Icons.close_rounded, size: 18, color: vc.muted),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
