import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'realtime_providers.dart';

/// Joins a campaign Socket.IO room while visible (pool/brief updates).
class CampaignRealtimeScope extends ConsumerStatefulWidget {
  const CampaignRealtimeScope({
    super.key,
    required this.campaignId,
    required this.child,
  });

  final String campaignId;
  final Widget child;

  @override
  ConsumerState<CampaignRealtimeScope> createState() =>
      _CampaignRealtimeScopeState();
}

class _CampaignRealtimeScopeState extends ConsumerState<CampaignRealtimeScope> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(realtimeServiceProvider).joinCampaignRoom(widget.campaignId);
    });
  }

  @override
  void didUpdateWidget(CampaignRealtimeScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.campaignId != widget.campaignId) {
      ref.read(realtimeServiceProvider).leaveCampaignRoom(oldWidget.campaignId);
      ref.read(realtimeServiceProvider).joinCampaignRoom(widget.campaignId);
    }
  }

  @override
  void dispose() {
    final campaignId = widget.campaignId;
    super.dispose();
    // Read service directly from container to avoid "ref after dispose" error
    try {
      ProviderScope.containerOf(context, listen: false)
          .read(realtimeServiceProvider)
          .leaveCampaignRoom(campaignId);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
