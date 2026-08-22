import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_guardian/features/connection/presentation/pages/connection_list_page.dart';
import 'package:ondam_guardian/features/connection/presentation/providers/connection_di_providers.dart';
import 'package:ondam_models/ondam_models.dart';

import '../features/connection/domain/fakes/fake_connection_repository.dart';

/// Phase 11 통합 테스트 — "어르신 연결 관리" 화면에서 accepted 연결을
/// 해제하는 흐름. Senior 쪽 `guardian_list_flow_test.dart`의 보호자 앱
/// 대응 — 지금까지 domain usecase 단위 테스트만 있던 gap을 메운다.
void main() {
  GuardianLink link({required String id, required GuardianLinkStatus status}) =>
      GuardianLink(
        id: id,
        elderId: 'elder-$id',
        guardianId: 'guardian-1',
        status: status,
        createdAt: DateTime(2026, 1, 1),
      );

  testWidgets('pending 연결은 대기 문구만 보여주고 해제 버튼이 없다(수락/거절은 어르신 전용)', (
    tester,
  ) async {
    // ConnectionListPage는 BUG 1 수정으로 화면이 떠 있는 동안 주기적으로
    // 재조회하는 Timer.periodic을 시작한다 — 테스트 종료 시 위젯을
    // 언마운트해 dispose()가 그 Timer를 취소하게 해야 flutter_test의
    // "Timer still pending" 실패를 피할 수 있다.
    addTearDown(() => tester.pumpWidget(const SizedBox()));

    final fake = FakeConnectionRepository()
      ..getMyLinksResult = Ok([
        link(id: 'link-1', status: GuardianLinkStatus.pending),
      ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [connectionRepositoryProvider.overrideWithValue(fake)],
        child: const MaterialApp(home: ConnectionListPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('어르신 수락 대기 중'), findsOneWidget);
    expect(find.text('연결 해제'), findsNothing);
  });

  testWidgets('accepted 연결은 확인 다이얼로그를 거쳐 해제하면 목록에서 사라진다', (tester) async {
    addTearDown(() => tester.pumpWidget(const SizedBox()));

    final fake = FakeConnectionRepository()
      ..getMyLinksResult = Ok([
        link(id: 'link-1', status: GuardianLinkStatus.accepted),
      ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [connectionRepositoryProvider.overrideWithValue(fake)],
        child: const MaterialApp(home: ConnectionListPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('연결 해제'));
    await tester.pumpAndSettle();

    expect(find.text('연결을 해제할까요?'), findsOneWidget);
    expect(fake.revokeLinkCalls, isEmpty);

    fake.getMyLinksResult = const Ok([]);
    await tester.tap(find.text('해제'));
    await tester.pumpAndSettle();

    expect(fake.revokeLinkCalls, ['link-1']);
    expect(find.text('아직 연결된 어르신이 없습니다\n어르신 연결하기로 QR을 스캔해주세요'), findsOneWidget);
  });

  testWidgets('해제 확인 다이얼로그에서 취소하면 연결이 그대로 남아있다', (tester) async {
    addTearDown(() => tester.pumpWidget(const SizedBox()));

    final fake = FakeConnectionRepository()
      ..getMyLinksResult = Ok([
        link(id: 'link-1', status: GuardianLinkStatus.accepted),
      ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [connectionRepositoryProvider.overrideWithValue(fake)],
        child: const MaterialApp(home: ConnectionListPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('연결 해제'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    expect(fake.revokeLinkCalls, isEmpty);
    expect(find.text('연결됨'), findsOneWidget);
  });

  testWidgets('BUG 1: 화면이 열려 있는 동안 목록을 주기적으로 다시 조회하고, '
      '화면을 벗어나면 재조회를 멈춘다', (tester) async {
    final fake = FakeConnectionRepository()
      ..getMyLinksResult = Ok([
        link(id: 'link-1', status: GuardianLinkStatus.pending),
      ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [connectionRepositoryProvider.overrideWithValue(fake)],
        child: const MaterialApp(home: ConnectionListPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(fake.getMyLinksCallCount, 1);

    // 상대(어르신) 앱에서 수락한 상태 변화는 이 앱에 push/realtime으로
    // 통보되지 않으므로, 화면이 떠 있는 동안 주기적 재조회로 반영돼야
    // 한다(재실행 없이).
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(fake.getMyLinksCallCount, 2);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(fake.getMyLinksCallCount, 3);

    // 화면을 벗어나면(dispose) 주기적 재조회 Timer가 취소돼야 한다.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
    expect(fake.getMyLinksCallCount, 3);
  });
}
