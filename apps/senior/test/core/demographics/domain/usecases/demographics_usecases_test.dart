import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/core/demographics/domain/entities/demographics.dart';
import 'package:ondam_senior/core/demographics/domain/usecases/get_my_demographics_usecase.dart';
import 'package:ondam_senior/core/demographics/domain/usecases/save_demographics_usecase.dart';

import '../fakes/fake_demographics_repository.dart';

void main() {
  late FakeDemographicsRepository repository;

  setUp(() {
    repository = FakeDemographicsRepository();
  });

  group('GetMyDemographicsUseCase', () {
    test('저장된 정보가 없으면 null을 정직하게 반환한다', () async {
      repository.getMyDemographicsResult = const Ok(null);
      final useCase = GetMyDemographicsUseCase(repository);

      final result = await useCase();

      expect((result as Ok<Demographics?>).value, isNull);
    });

    test('저장된 정보가 있으면 그대로 반환한다', () async {
      const demographics = Demographics(age: 72, gender: Gender.female);
      repository.getMyDemographicsResult = const Ok(demographics);
      final useCase = GetMyDemographicsUseCase(repository);

      final result = await useCase();

      expect((result as Ok<Demographics?>).value, demographics);
    });
  });

  group('SaveDemographicsUseCase', () {
    test('저장 성공', () async {
      final useCase = SaveDemographicsUseCase(repository);
      const demographics = Demographics(age: 72, gender: Gender.female);

      final result = await useCase(demographics);

      expect(result, isA<Ok<void>>());
      expect(repository.saveCalls, 1);
      expect(repository.savedDemographics, demographics);
    });

    test('나이가 없으면 저장을 시도하지 않고 ValidationFailure를 반환한다', () async {
      final useCase = SaveDemographicsUseCase(repository);
      const demographics = Demographics(age: null, gender: Gender.female);

      final result = await useCase(demographics);

      expect(result, isA<Err<void>>());
      expect((result as Err<void>).failure, isA<ValidationFailure>());
      expect(repository.saveCalls, 0);
    });

    test('나이가 범위를 벗어나면 저장을 시도하지 않는다', () async {
      final useCase = SaveDemographicsUseCase(repository);
      const demographics = Demographics(age: 150, gender: Gender.male);

      final result = await useCase(demographics);

      expect((result as Err<void>).failure, isA<ValidationFailure>());
      expect(repository.saveCalls, 0);
    });

    test('성별이 없으면 저장을 시도하지 않는다', () async {
      final useCase = SaveDemographicsUseCase(repository);
      const demographics = Demographics(age: 72, gender: null);

      final result = await useCase(demographics);

      expect((result as Err<void>).failure, isA<ValidationFailure>());
      expect(repository.saveCalls, 0);
    });

    test('저장 실패(예: 네트워크 오류)를 그대로 전달한다', () async {
      repository.saveDemographicsResult = const Err(ServerFailure());
      final useCase = SaveDemographicsUseCase(repository);
      const demographics = Demographics(age: 72, gender: Gender.female);

      final result = await useCase(demographics);

      expect((result as Err<void>).failure, isA<ServerFailure>());
    });
  });
}
