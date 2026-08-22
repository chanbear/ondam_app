import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_senior/core/auth/pin_verified_provider.dart';
import 'package:ondam_senior/features/auth/presentation/providers/auth_di_providers.dart';
import 'package:ondam_senior/features/settings/presentation/pages/settings_page.dart';
import 'package:ondam_senior/l10n/generated/app_localizations.dart';

import '../features/auth/domain/fakes/fake_auth_repository.dart';

/// Phase 11 통합 테스트 — "설정 → 회원 탈퇴 확인 → 탈퇴" 전체 흐름.
/// 계정 삭제(Edge Function `delete-account`, 서버측 cascade)는 이 환경에
/// 실제 Supabase 프로젝트가 없어 NOT AVAILABLE — 대신 클라이언트가 탈퇴
/// 성공 후 실제로 해야 하는 일(로컬 세션 종료 + PIN 게이트 초기화)이
/// 실행되는지 검증한다. 이 테스트를 작성하며 `signOutUseCase` 호출이
/// 누락돼 있던 실제 버그를 발견해 `PinNotifier.deleteAccount()`에서
/// 수정했다(탈퇴 후에도 로컬 세션이 남아 라우터가 PIN 입력 화면으로 보낼
/// 수 있었던 문제).
void main() {
  testWidgets('탈퇴를 확정하면 계정 삭제 요청 + 로컬 세션 종료 + PIN 게이트 초기화가 모두 일어난다', (
    tester,
  ) async {
    final fakeAuthRepository = FakeAuthRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(fakeAuthRepository)],
    );
    addTearDown(container.dispose);

    // 탈퇴 전: PIN 게이트가 이미 통과된 상태를 흉내낸다(실제로는 PIN 입력
    // 화면을 거쳐 여기 도달하지만, SettingsPage 자체를 독립적으로
    // 마운트하는 이 테스트에서는 사전 상태로 직접 세팅).
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
    expect(
      fakeAuthRepository.signOutCalls,
      1,
      reason:
          '탈퇴 성공 후 로컬 Supabase 세션도 함께 종료돼야 라우터가 삭제된 계정을 위한 PIN 입력 화면으로'
          ' 보내지 않는다',
    );
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
