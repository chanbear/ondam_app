import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';
import 'package:ondam_senior/features/connection/presentation/pages/guardian_list_page.dart';
import 'package:ondam_senior/features/connection/presentation/providers/connection_di_providers.dart';

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

  testWidgets('pending 요청을 수락하면 accepted로 바뀐 목록이 다시 표시된다', (tester) async {
    final fake = FakeConnectionRepository()
      ..getGuardianLinksResult = Ok([
        link(id: 'link-1', status: GuardianLinkStatus.pending),
      ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [connectionRepositoryProvider.overrideWithValue(fake)],
        child: const MaterialApp(home: GuardianListPage()),
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
    final fake = FakeConnectionRepository()
      ..getGuardianLinksResult = Ok([
        link(id: 'link-1', status: GuardianLinkStatus.pending),
      ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [connectionRepositoryProvider.overrideWithValue(fake)],
        child: const MaterialApp(home: GuardianListPage()),
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
    final fake = FakeConnectionRepository()
      ..getGuardianLinksResult = Ok([
        link(id: 'link-1', status: GuardianLinkStatus.accepted),
      ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [connectionRepositoryProvider.overrideWithValue(fake)],
        child: const MaterialApp(home: GuardianListPage()),
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
}
