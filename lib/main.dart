import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/push/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Attribution for the Inter/Plus Jakarta Sans weights bundled under
  // assets/google_fonts/ (see pubspec.yaml) — shows up in the app's
  // standard Licenses page, per google_fonts' own bundling guidance.
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/google_fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(<String>['google_fonts'], license);
  });

  // Capture the message that launched the app (if any) as early as possible —
  // Firebase recommends reading this right after initializeApp() since
  // reading it late can miss it on some platforms. The router isn't ready
  // yet at this point (ProviderScope hasn't built), so we stash it and act
  // on it once auth/login has settled — see PushNotificationService.init().
  pendingLaunchMessage = await FirebaseMessaging.instance.getInitialMessage();

  runApp(const ProviderScope(child: HalchalApp()));
}
