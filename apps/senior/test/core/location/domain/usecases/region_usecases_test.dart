import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/core/location/domain/entities/region.dart';
import 'package:ondam_senior/core/location/domain/usecases/get_my_region_usecase.dart';
import 'package:ondam_senior/core/location/domain/usecases/save_region_usecase.dart';

import '../fakes/fake_region_repository.dart';

void main() {
  late FakeRegionRepository repository;

  setUp(() {
    repository = FakeRegionRepository();
  });

  group('GetMyRegionUseCase', () {
    test('저장된 지역이 없으면 null을 정직하게 반환한다', () async {
      repository.getMyRegionResult = const Ok(null);
      final useCase = GetMyRegionUseCase(repository);

      final result = await useCase();

      expect((result as Ok<Region?>).value, isNull);
    });

    test('저장된 지역이 있으면 그대로 반환한다', () async {
      const region = Region(sido: '서울특별시', sigungu: '강남구', dong: '역삼동');
      repository.getMyRegionResult = const Ok(region);
      final useCase = GetMyRegionUseCase(repository);

      final result = await useCase();

      expect((result as Ok<Region?>).value, region);
    });
  });

  group('SaveRegionUseCase', () {
    test('저장 성공', () async {
      final useCase = SaveRegionUseCase(repository);
      const region = Region(sido: '서울특별시', sigungu: '강남구', dong: '역삼동');

      final result = await useCase(region);

      expect(result, isA<Ok<void>>());
      expect(repository.saveCalls, 1);
      expect(repository.savedRegion, region);
    });

    test('시/도가 비어 있으면 저장을 시도하지 않고 ValidationFailure를 반환한다', () async {
      final useCase = SaveRegionUseCase(repository);
      const region = Region(sido: '', sigungu: '강남구', dong: '역삼동');

      final result = await useCase(region);

      expect(result, isA<Err<void>>());
      expect((result as Err<void>).failure, isA<ValidationFailure>());
      expect(repository.saveCalls, 0);
    });

    test('저장 실패(예: 네트워크 오류)를 그대로 전달한다', () async {
      repository.saveRegionResult = const Err(ServerFailure());
      final useCase = SaveRegionUseCase(repository);
      const region = Region(sido: '서울특별시', sigungu: '강남구', dong: '역삼동');

      final result = await useCase(region);

      expect(result, isA<Err<void>>());
      expect((result as Err<void>).failure, isA<ServerFailure>());
    });
  });
}
