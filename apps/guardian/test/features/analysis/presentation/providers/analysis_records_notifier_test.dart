import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_guardian/features/analysis/domain/usecases/get_analysis_records_usecase.dart';
import 'package:ondam_guardian/features/analysis/presentation/providers/analysis_di_providers.dart';
import 'package:ondam_guardian/features/analysis/presentation/providers/analysis_records_notifier.dart';
import 'package:ondam_guardian/features/connection/presentation/providers/connected_elders_provider.dart';
import 'package:ondam_models/ondam_models.dart';

import '../../domain/fakes/fake_analysis_repository.dart';

AnalysisResult _record(String elderId, String summary) {
  return AnalysisResult(
    id: 'r-$elderId-$summary',
    elderId: elderId,
    type: AnalysisType.message,
    reliability: ReliabilityLevel.high,
    summary: summary,
    createdAt: DateTime(2026, 8, 1),
  );
}

void main() {
  test('선택된 어르신이 없으면 조회 없이 빈 목록을 반환한다', () async {
    final repository = FakeAnalysisRepository();
    final container = ProviderContainer(
      overrides: [
        getAnalysisRecordsUseCaseProvider.overrideWithValue(
          GetAnalysisRecordsUseCase(repository),
        ),
      ],
    );
    addTearDown(container.dispose);

    final records = await container.read(analysisRecordsProvider.future);

    expect(records, isEmpty);
    expect(repository.getRecordsForElderCalls, isEmpty);
  });

  test('어르신을 선택하면 해당 elderId로 조회한다', () async {
    final repository = FakeAnalysisRepository();
    repository.getRecordsForElderResult = Ok([_record('elder-1', '요약1')]);
    final container = ProviderContainer(
      overrides: [
        getAnalysisRecordsUseCaseProvider.overrideWithValue(
          GetAnalysisRecordsUseCase(repository),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(selectedElderIdProvider.notifier).select('elder-1');
    final records = await container.read(analysisRecordsProvider.future);

    expect(repository.getRecordsForElderCalls, ['elder-1']);
    expect(records.single.summary, '요약1');
  });

  test('선택된 어르신을 바꾸면 새 elderId로 다시 조회한다', () async {
    final repository = FakeAnalysisRepository();
    final container = ProviderContainer(
      overrides: [
        getAnalysisRecordsUseCaseProvider.overrideWithValue(
          GetAnalysisRecordsUseCase(repository),
        ),
      ],
    );
    addTearDown(container.dispose);

    repository.getRecordsForElderResult = Ok([_record('elder-1', '요약1')]);
    container.read(selectedElderIdProvider.notifier).select('elder-1');
    var records = await container.read(analysisRecordsProvider.future);
    expect(records.single.summary, '요약1');

    repository.getRecordsForElderResult = Ok([_record('elder-2', '요약2')]);
    container.read(selectedElderIdProvider.notifier).select('elder-2');
    records = await container.read(analysisRecordsProvider.future);

    expect(repository.getRecordsForElderCalls, ['elder-1', 'elder-2']);
    expect(records.single.summary, '요약2');
  });
}
