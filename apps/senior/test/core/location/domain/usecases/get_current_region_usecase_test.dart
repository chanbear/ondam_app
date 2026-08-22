import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/core/location/domain/entities/region.dart';
import 'package:ondam_senior/core/location/domain/usecases/get_current_region_usecase.dart';

import '../fakes/fake_location_repository.dart';

void main() {
  late FakeLocationRepository repository;

  setUp(() {
    repository = FakeLocationRepository();
  });

  test('GPS+reverse geocoding 성공 시 Region을 그대로 전달한다', () async {
    const region = Region(sido: '경기도', sigungu: '수원시', dong: '인계동');
    repository.currentRegionResult = const Ok(region);
    final useCase = GetCurrentRegionUseCase(repository);

    final result = await useCase();

    expect((result as Ok<Region>).value, region);
    expect(repository.getCurrentRegionCalls, 1);
  });

  test('위치를 가져오지 못하면 LocationFailure를 그대로 전달한다', () async {
    repository.currentRegionResult = const Err(
      LocationFailure('현재 위치를 확인할 수 없어요.'),
    );
    final useCase = GetCurrentRegionUseCase(repository);

    final result = await useCase();

    expect(result, isA<Err<Region>>());
    expect((result as Err<Region>).failure, isA<LocationFailure>());
  });

  test('reverse geocoding 실패도 LocationFailure로 전달한다', () async {
    repository.currentRegionResult = const Err(
      LocationFailure('현재 위치를 지역명으로 바꾸지 못했어요.'),
    );
    final useCase = GetCurrentRegionUseCase(repository);

    final result = await useCase();

    expect((result as Err<Region>).failure.message, '현재 위치를 지역명으로 바꾸지 못했어요.');
  });
}
