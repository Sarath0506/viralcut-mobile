import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/widgets/vc_scaffold.dart';
import '../../theme/viralcut_colors.dart';
import '../profile/profile_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Future<void> _markAllRead(WidgetRef ref) async {
    await ref.read(apiClientProvider).markAllNotificationsRead();
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadNotificationCountProvider);
  }

  Future<void> _onTapNotification(
    BuildContext context,
    WidgetRef ref,
    AppNotification n,
  ) async {
    if (!n.read) {
      await ref.read(apiClientProvider).markNotificationRead(n.id);
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadNotificationCountProvider);
    }
    if (n.link != null && n.link!.isNotEmpty && context.mounted) {
      context.push(n.link!);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final vc = ViralCutColors.of(context);

    return VcScaffold(
      title: 'Notifications',
      showBack: true,
      actions: [
        TextButton(
          onPressed: () => _markAllRead(ref),
          child: const Text('Mark all read'),
        ),
      ],
      body: notifications.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications_none_rounded,
                        size: 48, color: vc.muted),
                    const SizedBox(height: 12),
                    Text(
                      'No notifications yet',
                      style: TextStyle(color: vc.muted, fontSize: 14),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(notificationsProvider);
              ref.invalidate(unreadNotificationCountProvider);
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final n = items[i];
                return _NotificationTile(
                  notification: n,
                  vc: vc,
                  onTap: () => _onTapNotification(context, ref, n),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

(IconData, Color) _iconForType(String type, ViralCutColors vc) {
  if (type.contains('rejected')) {
    return (Icons.report_problem_outlined, vc.error);
  }
  if (type.contains('approved') || type.contains('earning')) {
    return (Icons.check_circle_outline_rounded, vc.money);
  }
  if (type.contains('withdrawal')) {
    return (Icons.account_balance_outlined, vc.primary);
  }
  if (type.contains('task')) {
    return (Icons.assignment_outlined, vc.primary);
  }
  return (Icons.notifications_none_rounded, vc.muted);
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.vc,
    required this.onTap,
  });

  final AppNotification notification;
  final ViralCutColors vc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final time = DateFormat('d MMM, h:mm a')
        .format(DateTime.parse(n.createdAt).toLocal());
    final (icon, iconColor) = _iconForType(n.type, vc);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: n.read ? vc.surface : vc.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: n.read ? vc.border : vc.primary.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 17, color: iconColor),
            ),
            if (!n.read)
              Padding(
                padding: const EdgeInsets.only(top: 5, right: 8),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: vc.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n.title,
                    style: TextStyle(
                      fontWeight: n.read ? FontWeight.w600 : FontWeight.w800,
                      fontSize: 14,
                      color: vc.onSurface,
                    ),
                  ),
                  if (n.body != null && n.body!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      n.body!,
                      style: TextStyle(fontSize: 13, color: vc.muted, height: 1.35),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    time,
                    style: TextStyle(fontSize: 11, color: vc.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
