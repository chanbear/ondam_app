import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_design_system/ondam_design_system.dart';
import 'package:ondam_guardian/features/analysis/domain/usecases/get_analysis_records_usecase.dart';
import 'package:ondam_guardian/features/analysis/presentation/providers/analysis_di_providers.dart';
import 'package:ondam_guardian/features/connection/presentation/providers/my_links_notifier.dart';
import 'package:ondam_guardian/features/home/presentation/pages/statistics_tab_page.dart';
import 'package:ondam_models/ondam_models.dart';

import '../../../analysis/domain/fakes/fake_analysis_repository.dart';

GuardianLink _link(String elderId) {
  return GuardianLink(
    id: 'link-$elderId',
    elderId: elderId,
    guardianId: 'guardian-1',
    status: GuardianLinkStatus.accepted,
    createdAt: DateTime(2026, 1, 1),
  );
}

class _FixedMyLinksNotifier extends MyLinksNotifier {
  _FixedMyLinksNotifier(this._links);

  final List<GuardianLink> _links;

  @override
  Future<List<GuardianLink>> build() async => _links;
}

AnalysisResult _doc(
  String elderId,
  String id, {
  int? billingAmountKrw,
  DateTime? createdAt,
}) {
  return AnalysisResult(
    id: id,
    elderId: elderId,
    type: AnalysisType.document,
    reliability: ReliabilityLevel.high,
    summary: '요약',
    createdAt: createdAt ?? DateTime(2026, 8, 1),
    billingAmountKrw: billingAmountKrw,
  );
}

Widget _wrap({
  required List<GuardianLink> links,
  required FakeAnalysisRepository repository,
}) {
  return ProviderScope(
    overrides: [
      myLinksProvider.overrideWith(() => _FixedMyLinksNotifier(links)),
      getAnalysisRecordsUseCaseProvider.overrideWithValue(
        GetAnalysisRecordsUseCase(repository),
      ),
    ],
    child: const MaterialApp(home: Scaffold(body: StatisticsTabPage())),
  );
}

void main() {
  testWidgets('연결된 어르신이 없으면 Empty State를 보여준다', (tester) async {
    await tester.pumpWidget(
      _wrap(links: const [], repository: FakeAnalysisRepository()),
    );
    await tester.pumpAndSettle();

    expect(find.text('아직 연결된 어르신이 없습니다.'), findsOneWidget);
    expect(find.byType(AppFeeStatisticsSection), findsNothing);
  });

  testWidgets('선택된 어르신에게 요금 기록이 있으면 요금 통계 섹션을 보여준다', (tester) async {
    final repository = FakeAnalysisRepository();
    repository.getRecordsForElderResult = Ok([
      _doc('elder-1', 'a1', billingAmountKrw: 50000),
    ]);

    await tester.pumpWidget(
      _wrap(links: [_link('elder-1')], repository: repository),
    );
    await tester.pumpAndSettle();

    expect(find.text('요금 통계'), findsOneWidget);
    expect(find.byType(AppFeeTrendChart), findsOneWidget);
    // 단일 기록이라 총/평균/최고 카드가 모두 같은 값을 보여준다.
    expect(find.text('50,000원'), findsWidgets);
    expect(repository.getRecordsForElderCalls, ['elder-1']);
  });

  testWidgets('요금 기록이 없으면 요금 통계 Empty State를 보여준다', (tester) async {
    final repository = FakeAnalysisRepository();
    repository.getRecordsForElderResult = Ok([_doc('elder-1', 'a1')]);

    await tester.pumpWidget(
      _wrap(links: [_link('elder-1')], repository: repository),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('아직 요금 통계가 없습니다.\n고지서나 요금서를 분석하면 통계가 만들어집니다.'),
      findsOneWidget,
    );
  });

  testWidgets('다른 어르신의 요금 기록은 섞이지 않는다', (tester) async {
    final repository = FakeAnalysisRepository();
    repository.getRecordsForElderResult = Ok([
      _doc('elder-1', 'a1', billingAmountKrw: 10000),
    ]);

    await tester.pumpWidget(
      _wrap(
        links: [_link('elder-1'), _link('elder-2')],
        repository: repository,
      ),
    );
    await tester.pumpAndSettle();

    // effectiveSelectedElderIdProvider defaults to the first connected elder.
    expect(repository.getRecordsForElderCalls, ['elder-1']);
    expect(repository.getRecordsForElderCalls, isNot(contains('elder-2')));
  });

  testWidgets('월별/연별 전환 버튼을 누르면 연별 추이로 바뀐다', (tester) async {
    final repository = FakeAnalysisRepository();
    repository.getRecordsForElderResult = Ok([
      _doc('elder-1', 'a1', billingAmountKrw: 10000),
    ]);

    await tester.pumpWidget(
      _wrap(links: [_link('elder-1')], repository: repository),
    );
    await tester.pumpAndSettle();

    expect(find.text('월별 요금 추이'), findsOneWidget);

    await tester.tap(find.text('연별'));
    await tester.pumpAndSettle();

    expect(find.text('연별 요금 추이'), findsOneWidget);
  });

  testWidgets('요금 추이 그래프는 접근성 요약 문장을 갖는다', (tester) async {
    final repository = FakeAnalysisRepository();
    repository.getRecordsForElderResult = Ok([
      _doc('elder-1', 'a1', billingAmountKrw: 10000),
    ]);

    await tester.pumpWidget(
      _wrap(links: [_link('elder-1')], repository: repository),
    );
    await tester.pumpAndSettle();

    final semantics = tester.getSemantics(find.byType(AppFeeTrendChart));
    expect(semantics.label, contains('요금 추이 그래프'));
  });
}
