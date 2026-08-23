import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/core/demographics/domain/entities/demographics.dart';
import 'package:ondam_senior/core/location/domain/entities/region.dart';
import 'package:ondam_senior/features/info/domain/entities/benefit_service.dart';
import 'package:ondam_senior/features/info/domain/usecases/search_benefit_services_usecase.dart';

import '../fakes/fake_benefit_service_repository.dart';

void main() {
  late FakeBenefitServiceRepository repository;
  const demographics = Demographics(age: 72, gender: Gender.female);
  const region = Region(sido: '서울특별시', sigungu: '강남구', dong: '역삼동');

  setUp(() {
    repository = FakeBenefitServiceRepository();
  });

  test('나이/성별이 없으면 검색을 시도하지 않고 ValidationFailure를 반환한다', () async {
    final useCase = SearchBenefitServicesUseCase(repository);

    final result = await useCase(
      const Demographics(age: null, gender: null),
      region,
    );

    expect(result, isA<Err<List<BenefitService>>>());
    expect(repository.searchCalls, 0);
  });

  test('지역이 없으면 검색을 시도하지 않고 ValidationFailure를 반환한다', () async {
    final useCase = SearchBenefitServicesUseCase(repository);

    final result = await useCase(demographics, null);

    expect(result, isA<Err<List<BenefitService>>>());
    expect(repository.searchCalls, 0);
  });

  test('나이/성별/지역이 모두 있으면 검색을 위임한다', () async {
    const services = [
      BenefitService(
        id: 'WLF001',
        source: BenefitServiceSource.central,
        title: '기초연금',
        summary: '만 65세 이상 지원',
      ),
    ];
    repository.searchResult = const Ok(services);
    final useCase = SearchBenefitServicesUseCase(repository);

    final result = await useCase(demographics, region);

    expect((result as Ok<List<BenefitService>>).value, services);
    expect(repository.lastSearchedDemographics, demographics);
    expect(repository.lastSearchedRegion, region);
  });

  test('결과가 없으면 빈 목록을 정직하게 반환한다', () async {
    repository.searchResult = const Ok([]);
    final useCase = SearchBenefitServicesUseCase(repository);

    final result = await useCase(demographics, region);

    expect((result as Ok<List<BenefitService>>).value, isEmpty);
  });

  test('검색 실패를 그대로 전달한다', () async {
    repository.searchResult = const Err(
      UnavailableFailure('맞춤 혜택 정보를 아직 제공하지 않아요.'),
    );
    final useCase = SearchBenefitServicesUseCase(repository);

    final result = await useCase(demographics, region);

    expect(
      (result as Err<List<BenefitService>>).failure,
      isA<UnavailableFailure>(),
    );
  });
}
