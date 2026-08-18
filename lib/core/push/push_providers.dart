import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../router/app_router.dart';
import 'push_notification_service.dart';

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService(ref.watch(routerProvider));
});
