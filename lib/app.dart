import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/realtime/realtime_sync.dart';
import 'core/router/app_router.dart';
import 'theme/theme_provider.dart';
import 'theme/halchal_theme.dart';

class HalchalApp extends ConsumerWidget {
  const HalchalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return RealtimeSync(
      child: MaterialApp.router(
        title: 'Halchal',
        debugShowCheckedModeBanner: false,
        theme: HalchalTheme.light,
        darkTheme: HalchalTheme.dark,
        themeMode: themeMode,
        routerConfig: router,
      ),
    );
  }
}
