import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/core/location/domain/entities/region.dart';
import 'package:ondam_senior/core/location/presentation/providers/location_di_providers.dart';
import 'package:ondam_senior/core/location/presentation/providers/region_provider.dart';

import '../../domain/fakes/fake_region_repository.dart';

void main() {
  test('저장 성공 후에는 요청 값을 그대로 믿지 않고 서버에서 다시 조회한다(저장 후 재조회)', () async {
    final repository = FakeRegionRepository();
    repository.getMyRegionResult = const Ok(null);
    final container = ProviderContainer(
      overrides: [regionRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(regionProvider.future);
    expect(repository.getMyRegionCalls, 1);

    const region = Region(sido: '서울특별시', sigungu: '강남구', dong: '역삼동');
    // 서버가 실제로 반환할 값을 미리 갱신해 둔다 — save()가 이 값을
    // 다시 읽어오는지 확인하기 위함이다.
    repository.getMyRegionResult = const Ok(region);

    final result = await container.read(regionProvider.notifier).save(region);

    expect(result, isA<Ok<void>>());
    expect(repository.saveCalls, 1);
    // save 한 번에 조회가 최소 한 번 더 일어나야 한다(재조회).
    expect(repository.getMyRegionCalls, greaterThanOrEqualTo(2));
    expect(container.read(regionProvider).value, region);
  });

  test('저장 실패 시에는 재조회하지 않는다', () async {
    final repository = FakeRegionRepository();
    repository.getMyRegionResult = const Ok(null);
    repository.saveRegionResult = const Err(ServerFailure());
    final container = ProviderContainer(
      overrides: [regionRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(regionProvider.future);
    final callsAfterInitialLoad = repository.getMyRegionCalls;

    const region = Region(sido: '서울특별시', sigungu: '강남구', dong: '역삼동');
    final result = await container.read(regionProvider.notifier).save(region);

    expect(result, isA<Err<void>>());
    expect(repository.getMyRegionCalls, callsAfterInitialLoad);
  });
}
