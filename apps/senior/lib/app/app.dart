import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../core/auth/idle_timeout_controller.dart';
import 'router/app_router.dart';

/// Root widget — wires theme and router together. Business logic does not
/// belong here; this is composition only.
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Instantiated once here so it lives for the app's lifetime — see
    // idle_timeout_controller.dart.
    ref.watch(idleTimeoutControllerProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'ondam_senior',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
    );
  }
}
