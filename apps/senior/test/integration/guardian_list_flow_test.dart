import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';
import 'package:ondam_senior/features/connection/presentation/pages/guardian_list_page.dart';
import 'package:ondam_senior/features/connection/presentation/providers/connection_di_providers.dart';
import 'package:ondam_senior/l10n/generated/app_localizations.dart';

import '../features/connection/domain/fakes/fake_connection_repository.dart';

/// Phase 11 통합 테스트 — "연결된 보호자 목록" 화면에서 pending 요청을
/// 수락/거절하면 실제로 목록이 갱신되는 흐름. 지금까지 `connection`
/// feature는 domain usecase 단위 테스트만 있었고 화면 단위(수락 탭 →
/// 목록이 실제로 바뀌는지) 테스트가 없던 gap을 메운다.
void main() {
  GuardianLink link({required String id, required GuardianLinkStatus status}) =>
      GuardianLink(
        id: id,
        elderId: 'elder-1',
        guardianId: 'guardian-$id',
        status: status,
        createdAt: DateTime(2026, 1, 1),
      );

  const wrapped = MaterialApp(
    locale: Locale('ko'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: GuardianListPage(),
  );

  testWidgets('pending 요청을 수락하면 accepted로 바뀐 목록이 다시 표시된다', (tester) async {
    // GuardianListPage는 BUG 1 수정으로 화면이 떠 있는 동안 주기적으로
    // 재조회하는 Timer.periodic을 시작한다 — 테스트 종료 시 위젯을
    // 언마운트해 dispose()가 그 Timer를 취소하게 해야 flutter_test의
    // "Timer still pending" 실패를 피할 수 있다.
    addTearDown(() => tester.pumpWidget(const SizedBox()));

    final fake = FakeConnectionRepository()
      ..getGuardianLinksResult = Ok([
        link(id: 'link-1', status: GuardianLinkStatus.pending),
      ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [connectionRepositoryProvider.overrideWithValue(fake)],
        child: wrapped,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('요청 대기 중'), findsOneWidget);
    expect(find.text('수락'), findsOneWidget);

    // 수락 탭 이후 재조회 결과를 accepted로 미리 세팅 —
    // GuardianLinksNotifier.respond()가 성공 시 invalidateSelf()로 다시
    // 이 값을 읽어온다(진짜 서버 상태 변화를 fake가 흉내내는 지점).
    fake.getGuardianLinksResult = Ok([
      link(id: 'link-1', status: GuardianLinkStatus.accepted),
    ]);

    await tester.tap(find.text('수락'));
    await tester.pumpAndSettle();

    expect(fake.respondToRequestCalls, [(linkId: 'link-1', accept: true)]);
    expect(find.text('연결됨'), findsOneWidget);
    expect(find.text('연결 해제'), findsOneWidget);
    expect(find.text('수락'), findsNothing);
  });

  testWidgets('pending 요청을 거절하면 목록에서 사라진다(rejected는 숨김)', (tester) async {
    addTearDown(() => tester.pumpWidget(const SizedBox()));

    final fake = FakeConnectionRepository()
      ..getGuardianLinksResult = Ok([
        link(id: 'link-1', status: GuardianLinkStatus.pending),
      ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [connectionRepositoryProvider.overrideWithValue(fake)],
        child: wrapped,
      ),
    );
    await tester.pumpAndSettle();

    fake.getGuardianLinksResult = Ok([
      link(id: 'link-1', status: GuardianLinkStatus.rejected),
    ]);

    await tester.tap(find.text('거절'));
    await tester.pumpAndSettle();

    expect(fake.respondToRequestCalls, [(linkId: 'link-1', accept: false)]);
    // rejected 상태는 GuardianListPage가 의도적으로 숨긴다 — 빈 상태
    // 안내로 대체된다.
    expect(find.text('아직 연결된 보호자가 없습니다\n보호자 연결하기로 QR을 보여주세요'), findsOneWidget);
  });

  testWidgets('accepted 연결을 해제하려면 확인 다이얼로그를 거쳐야 한다', (tester) async {
    addTearDown(() => tester.pumpWidget(const SizedBox()));

    final fake = FakeConnectionRepository()
      ..getGuardianLinksResult = Ok([
        link(id: 'link-1', status: GuardianLinkStatus.accepted),
      ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [connectionRepositoryProvider.overrideWithValue(fake)],
        child: wrapped,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('연결 해제'));
    await tester.pumpAndSettle();

    expect(find.text('연결을 해제할까요?'), findsOneWidget);
    expect(fake.revokeLinkCalls, isEmpty);

    fake.getGuardianLinksResult = const Ok([]);
    await tester.tap(find.text('해제'));
    await tester.pumpAndSettle();

    expect(fake.revokeLinkCalls, ['link-1']);
    expect(find.text('아직 연결된 보호자가 없습니다\n보호자 연결하기로 QR을 보여주세요'), findsOneWidget);
  });

  testWidgets('BUG 1: 화면이 열려 있는 동안 목록을 주기적으로 다시 조회하고, '
      '화면을 벗어나면 재조회를 멈춘다', (tester) async {
    final fake = FakeConnectionRepository()
      ..getGuardianLinksResult = Ok([
        link(id: 'link-1', status: GuardianLinkStatus.pending),
      ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [connectionRepositoryProvider.overrideWithValue(fake)],
        child: wrapped,
      ),
    );
    await tester.pumpAndSettle();
    expect(fake.getGuardianLinksCallCount, 1);

    // 상대(보호자) 앱에서 수락한 상태 변화는 이 앱에 push/realtime으로
    // 통보되지 않으므로, 화면이 떠 있는 동안 주기적 재조회로 반영돼야
    // 한다(재실행 없이).
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(fake.getGuardianLinksCallCount, 2);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(fake.getGuardianLinksCallCount, 3);

    // 화면을 벗어나면(dispose) 주기적 재조회 Timer가 취소돼야 한다.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
    expect(fake.getGuardianLinksCallCount, 3);
  });
}
