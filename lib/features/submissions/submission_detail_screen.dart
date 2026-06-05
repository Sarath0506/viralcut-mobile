import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/format/money_format.dart';
import '../../core/widgets/status_pill.dart';
import '../../core/widgets/vc_scaffold.dart';
import '../../theme/token_colors.dart';

final submissionDetailProvider =
    FutureProvider.family<SubmissionDetail, String>((ref, id) async {
  return ref.read(apiClientProvider).fetchSubmission(id);
});

class SubmissionDetailScreen extends ConsumerStatefulWidget {
  const SubmissionDetailScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<SubmissionDetailScreen> createState() =>
      _SubmissionDetailScreenState();
}

class _SubmissionDetailScreenState extends ConsumerState<SubmissionDetailScreen> {
  final _linkController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(submissionDetailProvider(widget.id));

    return detail.when(
      loading: () => const VcScaffold(
        title: 'Submission',
        showBack: true,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => VcScaffold(
        title: 'Submission',
        showBack: true,
        body: Center(child: Text('$e')),
      ),
      data: (s) {
        final awaitingLink = s.status == 'awaiting_live_link';
        final tracking = s.status == 'live_tracking';

        return VcScaffold(
          title: 'Submission details',
          showBack: true,
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              StatusPill(status: s.status),
              const SizedBox(height: 12),
              if (s.rejectionReason != null)
                Text(
                  s.rejectionReason!,
                  style: const TextStyle(color: ViralCutTokenColors.errorLight),
                ),
              if (awaitingLink) ...[
                const SizedBox(height: 16),
                const Text(
                  'Your content is approved. Post on Instagram, then paste your live reel URL.',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _linkController,
                  decoration: const InputDecoration(
                    labelText: 'Instagram reel URL',
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _loading
                      ? null
                      : () async {
                          setState(() => _loading = true);
                          try {
                            await ref.read(apiClientProvider).submitLiveLink(
                                  submissionId: widget.id,
                                  liveReelUrl: _linkController.text.trim(),
                                );
                            ref.invalidate(
                              submissionDetailProvider(widget.id),
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Live link submitted'),
                                ),
                              );
                            }
                          } on ApiException catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.message)),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _loading = false);
                          }
                        },
                  child: Text(
                    _loading ? 'Submitting…' : 'Submit reel link for payment',
                  ),
                ),
              ],
              if (tracking) ...[
                const SizedBox(height: 24),
                Text(
                  'Performance & earnings',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  s.ratePer1kDisplay,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _Metric(label: 'Views', value: '${s.eligibleViews}'),
                    _Metric(
                      label: 'Estimated',
                      value: formatPaise(s.estimatedPaise),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
