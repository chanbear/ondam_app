import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/core/location/domain/entities/region.dart';
import 'package:ondam_senior/features/welfare_center/domain/entities/senior_center.dart';
import 'package:ondam_senior/features/welfare_center/domain/usecases/search_welfare_centers_usecase.dart';

import '../fakes/fake_welfare_center_repository.dart';

void main() {
  late FakeWelfareCenterRepository repository;
  const region = Region(sido: '서울특별시', sigungu: '강남구', dong: '역삼동');

  setUp(() {
    repository = FakeWelfareCenterRepository();
  });

  test('지역이 없으면 검색을 시도하지 않고 ValidationFailure를 반환한다', () async {
    final useCase = SearchWelfareCentersUseCase(repository);

    final result = await useCase(null);

    expect(result, isA<Err<List<SeniorCenter>>>());
    expect(
      (result as Err<List<SeniorCenter>>).failure,
      isA<ValidationFailure>(),
    );
    expect(repository.searchCalls, 0);
  });

  test('지역이 있으면 그 지역으로 검색을 위임한다', () async {
    const centers = [
      SeniorCenter(id: '1', name: '역삼경로당', address: '서울 강남구 역삼동 1'),
    ];
    repository.searchResult = const Ok(centers);
    final useCase = SearchWelfareCentersUseCase(repository);

    final result = await useCase(region);

    expect((result as Ok<List<SeniorCenter>>).value, centers);
    expect(repository.lastSearchedRegion, region);
  });

  test('결과가 없으면 빈 목록을 정직하게 반환한다', () async {
    repository.searchResult = const Ok([]);
    final useCase = SearchWelfareCentersUseCase(repository);

    final result = await useCase(region);

    expect((result as Ok<List<SeniorCenter>>).value, isEmpty);
  });

  test('검색 실패를 그대로 전달한다', () async {
    repository.searchResult = const Err(
      UnavailableFailure('경로당 정보를 아직 제공하지 않아요.'),
    );
    final useCase = SearchWelfareCentersUseCase(repository);

    final result = await useCase(region);

    expect(
      (result as Err<List<SeniorCenter>>).failure,
      isA<UnavailableFailure>(),
    );
  });
}
