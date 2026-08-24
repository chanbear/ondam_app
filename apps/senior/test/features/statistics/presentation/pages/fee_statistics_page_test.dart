import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';
import 'package:ondam_senior/features/analysis/domain/usecases/get_my_analysis_records_usecase.dart';
import 'package:ondam_senior/features/analysis/presentation/providers/analysis_records_di_providers.dart';
import 'package:ondam_senior/features/statistics/presentation/pages/fee_statistics_page.dart';
import 'package:ondam_senior/l10n/generated/app_localizations.dart';

import '../../../analysis/domain/fakes/fake_analysis_records_repository.dart';

AnalysisResult _doc(String id, {int? billingAmountKrw, DateTime? createdAt}) {
  return AnalysisResult(
    id: id,
    elderId: 'e1',
    type: AnalysisType.document,
    reliability: ReliabilityLevel.high,
    summary: '요약',
    createdAt: createdAt ?? DateTime(2026, 8, 1),
    billingAmountKrw: billingAmountKrw,
  );
}

Widget wrap(FakeAnalysisRecordsRepository repository) {
  return ProviderScope(
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
      home: const FeeStatisticsPage(),
    ),
  );
}

void main() {
  testWidgets('로딩 중에는 AppLoading을 보여준다', (tester) async {
    await tester.pumpWidget(wrap(FakeAnalysisRecordsRepository()));

    expect(find.text('요금 통계를 불러오고 있어요'), findsOneWidget);
  });

  testWidgets('금액이 있는 문서 기록이 없으면 요금 통계 Empty State를 보여준다', (tester) async {
    final repository = FakeAnalysisRecordsRepository()
      ..getMyRecordsResult = Ok([_doc('a1')]);
    await tester.pumpWidget(wrap(repository));
    await tester.pumpAndSettle();

    expect(
      find.text('아직 요금 통계가 없습니다.\n고지서나 요금서를 분석하면 통계가 만들어집니다.'),
      findsOneWidget,
    );
  });

  testWidgets('금액이 있는 문서 기록이 있으면 요금 통계 카드를 보여준다', (tester) async {
    final repository = FakeAnalysisRecordsRepository()
      ..getMyRecordsResult = Ok([
        _doc('a1', billingAmountKrw: 32000, createdAt: DateTime(2026, 8, 1)),
      ]);
    await tester.pumpWidget(wrap(repository));
    await tester.pumpAndSettle();

    expect(find.text('총 요금'), findsOneWidget);
    // 단일 기록이라 총/평균/최고 카드가 모두 같은 값을 보여준다.
    expect(find.text('32,000원'), findsWidgets);
  });

  testWidgets('에러가 나면 AppError와 다시 시도 버튼을 보여준다', (tester) async {
    final repository = FakeAnalysisRecordsRepository()
      ..getMyRecordsResult = const Err(ServerFailure());
    await tester.pumpWidget(wrap(repository));
    await tester.pumpAndSettle();

    expect(find.text('다시 시도'), findsOneWidget);
  });
}
