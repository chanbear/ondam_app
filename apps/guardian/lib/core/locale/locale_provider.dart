import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/storage_providers.dart';

const _localeKey = 'app_locale';

/// 앱이 지원하는 언어 — 언어 선택 UI(설정)와 `AppLocalizations.supportedLocales`가
/// 이 목록을 기준으로 삼는다.
const supportedAppLocales = [
  Locale('ko'),
  Locale('en'),
  Locale('zh'),
  Locale('ja'),
];

/// 기기 설정이라 `LocalStorageService`에 저장한다 — 계정이 아니라 기기에
/// 속하는 값(senior 앱의 `LocaleController`와 동일 패턴).
class LocaleController extends Notifier<Locale> {
  @override
  Locale build() {
    _restore();
    return const Locale('ko');
  }

  Future<void> _restore() async {
    final saved = await ref.read(localStorageProvider).getString(_localeKey);
    // provider가 이미 폐기됐을 수 있다(예: 화면 dispose 경합) — 그 상태에서
    // state를 쓰면 예외가 던져지므로 먼저 확인한다.
    if (!ref.mounted) return;
    state = supportedAppLocales.firstWhere(
      (locale) => locale.languageCode == saved,
      orElse: () => const Locale('ko'),
    );
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    await ref
        .read(localStorageProvider)
        .setString(_localeKey, locale.languageCode);
  }
}

final localeControllerProvider = NotifierProvider<LocaleController, Locale>(
  LocaleController.new,
);
