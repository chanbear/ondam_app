import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../core/auth/idle_timeout_controller.dart';
import '../core/locale/locale_provider.dart';
import '../features/onboarding/presentation/providers/accessibility_prefs_provider.dart';
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
    final router = ref.watch(appRouterProvider);
    final textScale = ref.watch(accessibilityPrefsProvider).textScale;
    final locale = ref.watch(localeControllerProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: '온담',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: router,
      // 설정의 글자 크기(보통/크게/아주 크게)를 앱 전체에 적용한다. 기기
      // 시스템 글자 크기 설정과 곱해서 겹치면(예: 시스템 200% + 앱 140%)
      // 예측 불가능하게 커지므로, 이 앱 자체의 명시적 설정값으로 완전히
      // 대체한다 — AppTextStyles 토큰들이 이미 시스템 스케일을 참조하지
      // 않는 고정 크기라 이 방식이 기존 설계와 일관된다.
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale.scaleFactor)),
          child: child!,
        );
      },
    );
  }
}
