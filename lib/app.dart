import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/realtime/realtime_sync.dart';
import 'core/router/app_router.dart';
import 'theme/theme_provider.dart';
import 'theme/viralcut_theme.dart';

class ViralCutApp extends ConsumerWidget {
  const ViralCutApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return RealtimeSync(
      child: MaterialApp.router(
        title: 'Halchal',
        debugShowCheckedModeBanner: false,
        theme: ViralCutTheme.light,
        darkTheme: ViralCutTheme.dark,
        themeMode: themeMode,
        routerConfig: router,
      ),
    );
  }
}
