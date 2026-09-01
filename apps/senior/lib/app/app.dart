import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../core/auth/idle_timeout_controller.dart';
import '../core/easy_mode/easy_mode_provider.dart';
import '../core/locale/locale_provider.dart';
import '../features/onboarding/presentation/providers/accessibility_prefs_provider.dart';
import '../l10n/generated/app_localizations.dart';
import 'router/app_router.dart';

/// 쉬운 모드에서 글자 크기(보통/크게/아주 크게) 배율 위에 추가로 곱하는
/// 배율. 그동안 화면별로 `easyMode ? AppTextStyles.titleMedium : ...`처럼
/// 개별 위젯 단위로만 글자를 키워왔는데, 그 개별 처리가 빠진 위젯(예:
/// SettingsPage의 SwitchListTile/ListTile 타이틀)은 쉬운 모드를 켜도 전혀
/// 안 커지는 문제가 반복됐다(ui-prototype에서도 [data-easy="true"] 개별
/// 규칙 하나가 CSS 명시도 문제로 아예 적용 안 되던 것과 같은 종류의 버그).
/// 위젯 하나하나를 다 훑는 대신, 이미 있는 전역 textScaler(아래 builder)에
/// 배율을 하나 더 얹어 빠짐없이 전체 적용되게 한다.
const _easyModeExtraTextScale = 1.15;

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
    final easyMode = ref.watch(easyModeProvider);
    final locale = ref.watch(localeControllerProvider);
    final effectiveTextScale =
        textScale.scaleFactor * (easyMode ? _easyModeExtraTextScale : 1.0);

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
          ).copyWith(textScaler: TextScaler.linear(effectiveTextScale)),
          child: child!,
        );
      },
    );
  }
}
