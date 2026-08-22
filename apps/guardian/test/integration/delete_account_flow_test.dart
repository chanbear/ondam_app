import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_guardian/core/auth/pin_verified_provider.dart';
import 'package:ondam_guardian/features/auth/presentation/providers/auth_di_providers.dart';
import 'package:ondam_guardian/features/settings/presentation/pages/settings_page.dart';
import 'package:ondam_guardian/l10n/generated/app_localizations.dart';

import '../features/auth/domain/fakes/fake_auth_repository.dart';

/// Phase 11 통합 테스트 — Senior 앱과 동일한 회원 탈퇴 흐름 검증(같은 버그가
/// `PinNotifier.deleteAccount()`에 동일하게 있었음을 확인하고 함께 수정).
void main() {
  testWidgets('탈퇴를 확정하면 계정 삭제 요청 + 로컬 세션 종료 + PIN 게이트 초기화가 모두 일어난다', (
    tester,
  ) async {
    final fakeAuthRepository = FakeAuthRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(fakeAuthRepository)],
    );
    addTearDown(container.dispose);

    container.read(pinVerifiedProvider.notifier).markVerified();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsPage(),
        ),
      ),
    );

    // 언어 선택 섹션이 추가되며 '회원 탈퇴'가 기본 화면 밖으로 밀려날 수
    // 있다 — 스크롤 가능한 SettingsPage이므로 탭 전에 보이는 위치로 스크롤한다.
    await tester.ensureVisible(find.text('회원 탈퇴'));
    await tester.tap(find.text('회원 탈퇴'));
    await tester.pumpAndSettle();

    expect(find.text('정말 탈퇴하시겠어요?'), findsOneWidget);

    await tester.tap(find.text('탈퇴하기'));
    await tester.pumpAndSettle();

    expect(fakeAuthRepository.deleteAccountCalls, 1);
    expect(fakeAuthRepository.signOutCalls, 1);
    expect(container.read(pinVerifiedProvider), isFalse);
  });

  testWidgets('탈퇴 확인 다이얼로그에서 취소하면 아무 것도 호출되지 않는다', (tester) async {
    final fakeAuthRepository = FakeAuthRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(fakeAuthRepository)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsPage(),
        ),
      ),
    );

    // 언어 선택 섹션이 추가되며 '회원 탈퇴'가 기본 화면 밖으로 밀려날 수
    // 있다 — 스크롤 가능한 SettingsPage이므로 탭 전에 보이는 위치로 스크롤한다.
    await tester.ensureVisible(find.text('회원 탈퇴'));
    await tester.tap(find.text('회원 탈퇴'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    expect(fakeAuthRepository.deleteAccountCalls, 0);
    expect(fakeAuthRepository.signOutCalls, 0);
  });
}
