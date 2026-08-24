import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/core/location/domain/entities/region.dart';
import 'package:ondam_senior/features/support/domain/entities/local_gov_office.dart';
import 'package:ondam_senior/features/support/domain/usecases/search_local_gov_office_usecase.dart';

import '../fakes/fake_local_gov_office_repository.dart';

void main() {
  late FakeLocalGovOfficeRepository repository;
  const region = Region(sido: '서울특별시', sigungu: '강남구', dong: '역삼동');

  setUp(() {
    repository = FakeLocalGovOfficeRepository();
  });

  test('지역이 없으면 조회를 시도하지 않고 ValidationFailure를 반환한다', () async {
    final useCase = SearchLocalGovOfficeUseCase(repository);

    final result = await useCase(null);

    expect(result, isA<Err<LocalGovOffice?>>());
    expect((result as Err<LocalGovOffice?>).failure, isA<ValidationFailure>());
    expect(repository.searchCalls, 0);
  });

  test('지역이 있으면 그 지역으로 조회를 위임한다', () async {
    const office = LocalGovOffice(address: '서울특별시 강남구 테헤란로 1');
    repository.searchResult = const Ok(office);
    final useCase = SearchLocalGovOfficeUseCase(repository);

    final result = await useCase(region);

    expect((result as Ok<LocalGovOffice?>).value, office);
    expect(repository.lastSearchedRegion, region);
  });

  test('일치하는 기관이 없으면 null을 정직하게 반환한다', () async {
    repository.searchResult = const Ok(null);
    final useCase = SearchLocalGovOfficeUseCase(repository);

    final result = await useCase(region);

    expect((result as Ok<LocalGovOffice?>).value, isNull);
  });

  test('조회 실패를 그대로 전달한다', () async {
    repository.searchResult = const Err(
      UnavailableFailure('관할 행정복지센터 연락처를 아직 제공하지 않아요.'),
    );
    final useCase = SearchLocalGovOfficeUseCase(repository);

    final result = await useCase(region);

    expect((result as Err<LocalGovOffice?>).failure, isA<UnavailableFailure>());
  });
}
