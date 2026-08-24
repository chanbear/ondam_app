import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';
import 'package:ondam_senior/features/analysis/domain/usecases/get_my_analysis_records_usecase.dart';
import 'package:ondam_senior/features/analysis/presentation/pages/analysis_record_detail_page.dart';
import 'package:ondam_senior/features/analysis/presentation/providers/analysis_records_di_providers.dart';
import 'package:ondam_senior/features/home/presentation/pages/records_tab_page.dart';
import 'package:ondam_senior/l10n/generated/app_localizations.dart';

import '../../../analysis/domain/fakes/fake_analysis_records_repository.dart';

AnalysisResult _record(String id, String summary) {
  return AnalysisResult(
    id: id,
    elderId: 'e1',
    type: AnalysisType.document,
    reliability: ReliabilityLevel.high,
    summary: summary,
    createdAt: DateTime(2026, 8, 1, 9, 30),
    riskLevel: RiskLevel.safe,
  );
}

Widget wrap(FakeAnalysisRecordsRepository repository) {
  return ProviderScope(
    // Failure는 Dart Error가 아니라서 기본 재시도(최대 10회, 지수 백오프)가
    // 걸린다 — 에러 시나리오 테스트가 재시도 타이밍이 아니라 최종
    // AppError 렌더링을 검증하도록 재시도를 끈다.
    retry: (_, _) => null,
    overrides: [
      getMyAnalysisRecordsUseCaseProvider.overrideWithValue(
        GetMyAnalysisRecordsUseCase(repository),
      ),
    ],
    child: MaterialApp(
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: RecordsTabPage()),
    ),
  );
}

void main() {
  testWidgets('로딩 중에는 AppLoading을 보여준다', (tester) async {
    final repository = FakeAnalysisRecordsRepository();
    await tester.pumpWidget(wrap(repository));

    expect(find.text('기록을 불러오고 있어요'), findsOneWidget);
  });

  testWidgets('기록이 없으면 AppEmptyState를 보여준다', (tester) async {
    final repository = FakeAnalysisRecordsRepository();
    await tester.pumpWidget(wrap(repository));
    await tester.pumpAndSettle();

    expect(
      find.text('아직 분석한 기록이 없습니다.\n문서 찍기나 문자 보기를 이용해보세요.'),
      findsOneWidget,
    );
  });

  testWidgets('기록이 있으면 최신순으로 카드 목록을 보여준다', (tester) async {
    final repository = FakeAnalysisRecordsRepository()
      ..getMyRecordsResult = Ok([_record('a1', '요약1'), _record('a2', '요약2')]);
    await tester.pumpWidget(wrap(repository));
    await tester.pumpAndSettle();

    expect(find.text('요약1'), findsOneWidget);
    expect(find.text('요약2'), findsOneWidget);
  });

  testWidgets('에러가 나면 AppError와 다시 시도 버튼을 보여준다', (tester) async {
    final repository = FakeAnalysisRecordsRepository()
      ..getMyRecordsResult = const Err(ServerFailure());
    await tester.pumpWidget(wrap(repository));
    await tester.pumpAndSettle();

    expect(find.text('다시 시도'), findsOneWidget);
  });

  testWidgets('카드를 누르면 AnalysisRecordDetailPage로 이동한다', (tester) async {
    final repository = FakeAnalysisRecordsRepository()
      ..getMyRecordsResult = Ok([_record('a1', '요약1')]);
    await tester.pumpWidget(wrap(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('요약1'));
    await tester.pumpAndSettle();

    expect(find.byType(AnalysisRecordDetailPage), findsOneWidget);
  });
}
