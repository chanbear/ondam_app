import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';
import 'package:ondam_senior/features/analysis/domain/usecases/confirm_analysis_result_usecase.dart';
import 'package:ondam_senior/features/analysis/domain/usecases/get_my_analysis_records_usecase.dart';
import 'package:ondam_senior/features/analysis/presentation/providers/analysis_records_di_providers.dart';
import 'package:ondam_senior/features/analysis/presentation/providers/analysis_records_notifier.dart';

import '../../domain/fakes/fake_analysis_records_repository.dart';

AnalysisResult _record(String id, String summary) {
  return AnalysisResult(
    id: id,
    elderId: 'e1',
    type: AnalysisType.message,
    reliability: ReliabilityLevel.high,
    summary: summary,
    createdAt: DateTime(2026, 8, 1),
  );
}

void main() {
  test('본인 기록을 성공적으로 불러오면 그대로 노출한다', () async {
    final repository = FakeAnalysisRecordsRepository();
    repository.getMyRecordsResult = Ok([_record('a1', '요약1')]);
    final container = ProviderContainer(
      overrides: [
        getMyAnalysisRecordsUseCaseProvider.overrideWithValue(
          GetMyAnalysisRecordsUseCase(repository),
        ),
      ],
    );
    addTearDown(container.dispose);

    final records = await container.read(analysisRecordsProvider.future);

    expect(records.single.summary, '요약1');
    expect(repository.getMyRecordsCallCount, 1);
  });

  test('기록이 없으면 빈 목록을 반환한다 — 에러가 아니다', () async {
    final repository = FakeAnalysisRecordsRepository();
    final container = ProviderContainer(
      overrides: [
        getMyAnalysisRecordsUseCaseProvider.overrideWithValue(
          GetMyAnalysisRecordsUseCase(repository),
        ),
      ],
    );
    addTearDown(container.dispose);

    final records = await container.read(analysisRecordsProvider.future);

    expect(records, isEmpty);
  });

  test('Repository가 Failure를 반환하면 AsyncError로 전달된다', () async {
    final repository = FakeAnalysisRecordsRepository();
    repository.getMyRecordsResult = const Err(ServerFailure());
    // Failure는 Dart Error가 아니라서 ProviderContainer.defaultRetry가 최대
    // 10회까지 지수 백오프(200ms~6400ms)로 자동 재시도한다 — 테스트가
    // 검증하려는 것은 그 재시도 타이밍이 아니라 "결국 AsyncError로
    // 귀결되는가"이므로 재시도 자체를 끈다.
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        getMyAnalysisRecordsUseCaseProvider.overrideWithValue(
          GetMyAnalysisRecordsUseCase(repository),
        ),
      ],
    );
    addTearDown(container.dispose);

    await expectLater(
      container.read(analysisRecordsProvider.future),
      throwsA(isA<ServerFailure>()),
    );
  });

  test('invalidate 후 다시 읽으면 Repository를 다시 호출한다', () async {
    final repository = FakeAnalysisRecordsRepository();
    repository.getMyRecordsResult = Ok([_record('a1', '요약1')]);
    final container = ProviderContainer(
      overrides: [
        getMyAnalysisRecordsUseCaseProvider.overrideWithValue(
          GetMyAnalysisRecordsUseCase(repository),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(analysisRecordsProvider.future);
    container.invalidate(analysisRecordsProvider);
    repository.getMyRecordsResult = Ok([_record('a2', '요약2')]);
    final records = await container.read(analysisRecordsProvider.future);

    expect(repository.getMyRecordsCallCount, 2);
    expect(records.single.summary, '요약2');
  });

  group('confirm — ONDAM 2.0 PHASE 30: 목록 캐시 일관성', () {
    test('확인 완료가 성공하면 기록 목록도 함께 다시 조회한다', () async {
      final repository = FakeAnalysisRecordsRepository();
      repository.getMyRecordsResult = Ok([_record('a1', '요약1')]);
      final container = ProviderContainer(
        overrides: [
          getMyAnalysisRecordsUseCaseProvider.overrideWithValue(
            GetMyAnalysisRecordsUseCase(repository),
          ),
          confirmAnalysisResultUseCaseProvider.overrideWithValue(
            ConfirmAnalysisResultUseCase(repository),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(analysisRecordsProvider.future);
      expect(repository.getMyRecordsCallCount, 1);

      final result = await container
          .read(analysisRecordsProvider.notifier)
          .confirm('a1');

      expect(result, isA<Ok<void>>());
      expect(repository.confirmCalls, ['a1']);
      // 목록 → 상세 → 확인 완료 → 다시 목록 → 다시 상세로 돌아왔을 때 옛
      // confirmedAt: null 캐시가 남아있지 않도록 다시 조회해야 한다.
      expect(repository.getMyRecordsCallCount, 2);
    });

    test('확인 완료가 실패하면 목록을 다시 조회하지 않는다', () async {
      final repository = FakeAnalysisRecordsRepository();
      repository.getMyRecordsResult = Ok([_record('a1', '요약1')]);
      repository.confirmResult = const Err(ServerFailure());
      final container = ProviderContainer(
        overrides: [
          getMyAnalysisRecordsUseCaseProvider.overrideWithValue(
            GetMyAnalysisRecordsUseCase(repository),
          ),
          confirmAnalysisResultUseCaseProvider.overrideWithValue(
            ConfirmAnalysisResultUseCase(repository),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(analysisRecordsProvider.future);
      final callsAfterInitialLoad = repository.getMyRecordsCallCount;

      final result = await container
          .read(analysisRecordsProvider.notifier)
          .confirm('a1');

      expect(result, isA<Err<void>>());
      expect(repository.getMyRecordsCallCount, callsAfterInitialLoad);
    });
  });
}
