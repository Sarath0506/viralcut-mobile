import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/widgets/vc_scaffold.dart';
import '../../theme/viralcut_colors.dart';
import 'profile_providers.dart';

class _KycInfo {
  const _KycInfo({
    required this.icon,
    required this.label,
    required this.description,
  });

  final IconData icon;
  final String label;
  final String description;
}

_KycInfo _infoFor(String status, String? rejectionReason) {
  switch (status) {
    case 'pending':
      return const _KycInfo(
        icon: Icons.hourglass_top_rounded,
        label: 'Under review',
        description:
            'Your document has been submitted and is being reviewed. This usually takes 1-2 business days.',
      );
    case 'verified':
      return const _KycInfo(
        icon: Icons.verified_rounded,
        label: 'Verified',
        description:
            'Your identity has been verified. You\'re all set to receive payouts.',
      );
    case 'rejected':
      return _KycInfo(
        icon: Icons.report_problem_outlined,
        label: 'Rejected',
        description: rejectionReason?.isNotEmpty == true
            ? 'Your submission was rejected: $rejectionReason. Please resubmit with a clearer document.'
            : 'Your KYC submission was rejected. Please resubmit with a clearer document.',
      );
    default:
      return const _KycInfo(
        icon: Icons.pending_outlined,
        label: 'Not started',
        description:
            'Verification is required before you can withdraw earnings. Submit a government ID to get started.',
      );
  }
}

Color _colorFor(String status, ViralCutColors vc) {
  switch (status) {
    case 'verified':
      return vc.money;
    case 'rejected':
      return vc.error;
    case 'pending':
      return vc.warning;
    default:
      return vc.muted;
  }
}

const _documentTypes = [
  (key: 'aadhaar', label: 'Aadhaar Card', icon: Icons.badge_outlined),
  (key: 'pan', label: 'PAN Card', icon: Icons.credit_card_rounded),
  (key: 'passport', label: 'Passport', icon: Icons.flight_outlined),
  (
    key: 'driving_license',
    label: 'Driving License',
    icon: Icons.directions_car_filled_outlined
  ),
];

class KycStatusScreen extends ConsumerStatefulWidget {
  const KycStatusScreen({super.key});

  @override
  ConsumerState<KycStatusScreen> createState() => _KycStatusScreenState();
}

class _KycStatusScreenState extends ConsumerState<KycStatusScreen> {
  String _documentType = _documentTypes.first.key;
  XFile? _pickedFile;
  bool _submitting = false;

  Future<void> _pickFile() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (file != null) setState(() => _pickedFile = file);
  }

  Future<void> _submit() async {
    final file = _pickedFile;
    if (file == null) return;
    setState(() => _submitting = true);
    try {
      final ext = file.name.split('.').last.toLowerCase();
      final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
      await ref.read(apiClientProvider).submitKyc(
            filePath: file.path,
            fileName: file.name,
            mimeType: mime,
            documentType: _documentType,
          );
      ref.invalidate(profileMeProvider);
      setState(() => _pickedFile = null);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('KYC document submitted for review')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(profileMeProvider);
    final vc = ViralCutColors.of(context);

    return VcScaffold(
      title: 'KYC Status',
      showBack: true,
      body: me.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (user) {
          final status = user['kycStatus'] as String? ?? 'not_started';
          final rejectionReason = user['kycRejectionReason'] as String?;
          final info = _infoFor(status, rejectionReason);
          final color = _colorFor(status, vc);
          final canSubmit = status == 'not_started' || status == 'rejected';

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withValues(alpha: 0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(info.icon, color: color, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          info.label,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      info.description,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: vc.onSurface.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              if (canSubmit) ...[
                const SizedBox(height: 20),
                Text('Document type',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: vc.onSurface)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _documentTypes.map((d) {
                    final selected = _documentType == d.key;
                    return GestureDetector(
                      onTap: () => setState(() => _documentType = d.key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? vc.primary.withValues(alpha: 0.14)
                              : vc.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected ? vc.primary : vc.border,
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(d.icon,
                                size: 14,
                                color: selected ? vc.primary : vc.muted),
                            const SizedBox(width: 6),
                            Text(
                              d.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: selected ? vc.primary : vc.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text('Upload document',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: vc.onSurface)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickFile,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: vc.primary.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: vc.primary.withValues(alpha: 0.3)),
                    ),
                    child: _pickedFile != null
                        ? Column(children: [
                            Icon(Icons.check_circle_rounded,
                                color: vc.money, size: 28),
                            const SizedBox(height: 6),
                            Text(_pickedFile!.name,
                                style: TextStyle(fontSize: 12, color: vc.onSurface)),
                          ])
                        : Column(children: [
                            Icon(Icons.upload_file_outlined,
                                color: vc.primary, size: 28),
                            const SizedBox(height: 6),
                            Text('Tap to select a photo of your document',
                                style: TextStyle(fontSize: 12, color: vc.muted)),
                          ]),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: (_pickedFile == null || _submitting) ? null : _submit,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Submit for review'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
