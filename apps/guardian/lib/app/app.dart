import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../core/auth/idle_timeout_controller.dart';
import '../core/locale/locale_provider.dart';
import '../features/notification/presentation/services/push_notification_service.dart';
import '../l10n/generated/app_localizations.dart';
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
    // Same pattern — see push_notification_service.dart.
    ref.watch(pushNotificationControllerProvider);
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeControllerProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'ondam_guardian',
      theme: AppTheme.light.copyWith(
        scaffoldBackgroundColor: AppColors.surface,
        appBarTheme: AppTheme.light.appBarTheme.copyWith(
          backgroundColor: AppColors.surface,
        ),
      ),
      darkTheme: AppTheme.dark,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: router,
    );
  }
}
