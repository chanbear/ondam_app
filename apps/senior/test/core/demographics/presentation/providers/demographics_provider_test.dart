import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/core/demographics/domain/entities/demographics.dart';
import 'package:ondam_senior/core/demographics/presentation/providers/demographics_di_providers.dart';
import 'package:ondam_senior/core/demographics/presentation/providers/demographics_provider.dart';

import '../../domain/fakes/fake_demographics_repository.dart';

void main() {
  test('저장 성공 후에는 요청 값을 그대로 믿지 않고 서버에서 다시 조회한다(저장 후 재조회)', () async {
    final repository = FakeDemographicsRepository();
    repository.getMyDemographicsResult = const Ok(null);
    final container = ProviderContainer(
      overrides: [
        demographicsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(demographicsProvider.future);
    expect(repository.getMyDemographicsCalls, 1);

    const demographics = Demographics(age: 72, gender: Gender.female);
    repository.getMyDemographicsResult = const Ok(demographics);

    final result = await container
        .read(demographicsProvider.notifier)
        .save(demographics);

    expect(result, isA<Ok<void>>());
    expect(repository.saveCalls, 1);
    expect(repository.getMyDemographicsCalls, greaterThanOrEqualTo(2));
    expect(container.read(demographicsProvider).value, demographics);
  });

  test('저장 실패 시에는 재조회하지 않는다', () async {
    final repository = FakeDemographicsRepository();
    repository.getMyDemographicsResult = const Ok(null);
    repository.saveDemographicsResult = const Err(ServerFailure());
    final container = ProviderContainer(
      overrides: [
        demographicsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(demographicsProvider.future);
    final callsAfterInitialLoad = repository.getMyDemographicsCalls;

    const demographics = Demographics(age: 72, gender: Gender.female);
    final result = await container
        .read(demographicsProvider.notifier)
        .save(demographics);

    expect(result, isA<Err<void>>());
    expect(repository.getMyDemographicsCalls, callsAfterInitialLoad);
  });
}
