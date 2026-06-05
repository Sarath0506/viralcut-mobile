import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/widgets/vc_scaffold.dart';

class SubmitWorkScreen extends ConsumerStatefulWidget {
  const SubmitWorkScreen({super.key, required this.campaignId});

  final String campaignId;

  @override
  ConsumerState<SubmitWorkScreen> createState() => _SubmitWorkScreenState();
}

class _SubmitWorkScreenState extends ConsumerState<SubmitWorkScreen> {
  final _urlController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VcScaffold(
      title: 'Submit your work',
      showBack: true,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Paste a public Google Drive link to your draft clip. After brand approval, post on Instagram and submit your live reel link.',
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Google Drive link',
                hintText: 'https://drive.google.com/...',
              ),
            ),
            const Spacer(),
            FilledButton(
              onPressed: _loading
                  ? null
                  : () async {
                      setState(() => _loading = true);
                      try {
                        await ref.read(apiClientProvider).createSubmission(
                              campaignId: widget.campaignId,
                              draftDriveUrl: _urlController.text.trim(),
                            );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Submitted for review'),
                            ),
                          );
                          context.go('/submissions');
                        }
                      } on ApiException catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.message)),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _loading = false);
                      }
                    },
              child: Text(_loading ? 'Submitting…' : 'Submit for review'),
            ),
          ],
        ),
      ),
    );
  }
}
