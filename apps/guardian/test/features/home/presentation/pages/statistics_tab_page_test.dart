import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_design_system/ondam_design_system.dart';
import 'package:ondam_guardian/features/analysis/domain/usecases/get_analysis_records_usecase.dart';
import 'package:ondam_guardian/features/analysis/presentation/providers/analysis_di_providers.dart';
import 'package:ondam_guardian/features/connection/presentation/providers/my_links_notifier.dart';
import 'package:ondam_guardian/features/home/presentation/pages/statistics_tab_page.dart';
import 'package:ondam_guardian/l10n/generated/app_localizations.dart';
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
  RiskLevel? riskLevel,
}) {
  return AnalysisResult(
    id: id,
    elderId: elderId,
    type: AnalysisType.document,
    reliability: ReliabilityLevel.high,
    summary: '요약',
    createdAt: createdAt ?? DateTime(2026, 8, 1),
    billingAmountKrw: billingAmountKrw,
    riskLevel: riskLevel,
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
    child: MaterialApp(
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: StatisticsTabPage()),
    ),
  );
}

/// 최근 4주 활동 차트 + 완료/남은 일정 카드가 추가되면서 요금 통계 섹션이
/// 기본 테스트 뷰포트(800x600)보다 훨씬 아래로 밀렸다.
/// `ListView(children:...)`는 화면 밖 자식을 지연 빌드하므로, 스크롤을
/// 흉내 내는 대신 테스트 표면 자체를 넉넉하게 키워 모든 섹션이 한 번에
/// 빌드되게 한다(스크롤 델타/방향에 의존하는 것보다 안정적).
/// `setSurfaceSize`는 `testWidgets` 콜백 안(테스트 zone)에서만 호출할 수
/// 있어 `setUp`/`tearDown`에는 둘 수 없다 — 각 테스트 본문 첫 줄에서 부른다.
Future<void> _useTallSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(800, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

void main() {
  testWidgets('연결된 어르신이 없으면 Empty State를 보여준다', (tester) async {
    await _useTallSurface(tester);
    await tester.pumpWidget(
      _wrap(links: const [], repository: FakeAnalysisRepository()),
    );
    await tester.pumpAndSettle();

    expect(find.text('아직 연결된 어르신이 없습니다.'), findsOneWidget);
    expect(find.byType(AppFeeStatisticsSection), findsNothing);
  });

  testWidgets('선택된 어르신에게 요금 기록이 있으면 요금 통계 섹션을 보여준다', (tester) async {
    await _useTallSurface(tester);
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
    await _useTallSurface(tester);
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
    await _useTallSurface(tester);
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

  testWidgets('위험 문자나 남은 일정이 없으면 보호자 안심 요약에 안심 문구를 보여준다', (tester) async {
    await _useTallSurface(tester);
    final repository = FakeAnalysisRepository();
    repository.getRecordsForElderResult = Ok([_doc('elder-1', 'a1')]);

    await tester.pumpWidget(
      _wrap(links: [_link('elder-1')], repository: repository),
    );
    await tester.pumpAndSettle();

    expect(find.text('확인할 위험 건이나 남은 일정이 없어요'), findsOneWidget);
  });

  testWidgets('이번 달 위험 문자가 있으면 보호자 안심 요약에 위험 건수를 보여준다', (tester) async {
    await _useTallSurface(tester);
    final repository = FakeAnalysisRepository();
    repository.getRecordsForElderResult = Ok([
      AnalysisResult(
        id: 'm1',
        elderId: 'elder-1',
        type: AnalysisType.message,
        reliability: ReliabilityLevel.high,
        summary: '요약',
        createdAt: DateTime.now(),
        riskLevel: RiskLevel.dangerous,
      ),
    ]);

    await tester.pumpWidget(
      _wrap(links: [_link('elder-1')], repository: repository),
    );
    await tester.pumpAndSettle();

    expect(find.text('확인이 필요한 위험 건 1건 있어요'), findsOneWidget);
  });

  testWidgets('요금 추이 그래프는 접근성 요약 문장을 갖는다', (tester) async {
    await _useTallSurface(tester);
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
