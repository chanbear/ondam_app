import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/features/info/domain/entities/benefit_service.dart';
import 'package:ondam_senior/features/info/domain/entities/benefit_service_detail.dart';
import 'package:ondam_senior/features/info/domain/usecases/get_benefit_service_detail_usecase.dart';

import '../fakes/fake_benefit_service_repository.dart';

void main() {
  late FakeBenefitServiceRepository repository;

  setUp(() {
    repository = FakeBenefitServiceRepository();
  });

  test('id가 비어 있으면 조회를 시도하지 않고 ValidationFailure를 반환한다', () async {
    final useCase = GetBenefitServiceDetailUseCase(repository);

    final result = await useCase('', BenefitServiceSource.central);

    expect(result, isA<Err<BenefitServiceDetail>>());
    expect(repository.getDetailCalls, 0);
  });

  test('id가 있으면 조회를 위임한다', () async {
    const detail = BenefitServiceDetail(
      id: 'WLF001',
      title: '기초연금',
      summary: '만 65세 이상 지원',
    );
    repository.getDetailResult = const Ok(detail);
    final useCase = GetBenefitServiceDetailUseCase(repository);

    final result = await useCase('WLF001', BenefitServiceSource.central);

    expect((result as Ok<BenefitServiceDetail>).value, detail);
    expect(repository.lastDetailId, 'WLF001');
    expect(repository.lastDetailSource, BenefitServiceSource.central);
  });
}
