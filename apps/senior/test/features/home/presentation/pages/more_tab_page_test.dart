import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_senior/features/analysis/domain/usecases/get_my_analysis_records_usecase.dart';
import 'package:ondam_senior/features/analysis/presentation/providers/analysis_records_di_providers.dart';
import 'package:ondam_senior/features/home/presentation/pages/more_tab_page.dart';
import 'package:ondam_senior/l10n/generated/app_localizations.dart';

import '../../../analysis/domain/fakes/fake_analysis_records_repository.dart';

Widget _wrap(FakeAnalysisRecordsRepository repository) {
  return ProviderScope(
    overrides: [
      getMyAnalysisRecordsUseCaseProvider.overrideWithValue(
        GetMyAnalysisRecordsUseCase(repository),
      ),
    ],
    child: MaterialApp(
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const MoreTabPage(),
    ),
  );
}

void main() {
  testWidgets('통계 항목을 누르면 준비 중 화면이 아니라 요금 통계 화면으로 이동한다', (tester) async {
    await tester.pumpWidget(_wrap(FakeAnalysisRecordsRepository()));

    await tester.tap(find.text('통계'));
    await tester.pumpAndSettle();

    expect(find.text('요금 통계'), findsOneWidget);
    expect(find.text('이 기능은 아직 준비 중이에요.'), findsNothing);
  });
}
