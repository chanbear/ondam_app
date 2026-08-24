import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/core/demographics/data/datasources/demographics_remote_datasource.dart';
import 'package:ondam_senior/core/demographics/data/repositories/demographics_repository_impl.dart';
import 'package:ondam_senior/core/demographics/domain/entities/demographics.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockDemographicsRemoteDataSource extends Mock
    implements DemographicsRemoteDataSource {}

void main() {
  late _MockDemographicsRemoteDataSource dataSource;
  late DemographicsRepositoryImpl repository;

  setUp(() {
    dataSource = _MockDemographicsRemoteDataSource();
    repository = DemographicsRepositoryImpl(dataSource);
  });

  group('getMyDemographics', () {
    test('저장된 행이 없으면 null을 정직하게 반환한다', () async {
      when(() => dataSource.fetchMine()).thenAnswer((_) async => null);

      final result = await repository.getMyDemographics();

      expect((result as Ok<Demographics?>).value, isNull);
    });

    test('저장된 행이 있으면 엔티티로 변환한다', () async {
      when(
        () => dataSource.fetchMine(),
      ).thenAnswer((_) async => {'age': 72, 'gender': 'female'});

      final result = await repository.getMyDemographics();

      final value = (result as Ok<Demographics?>).value;
      expect(value?.age, 72);
      expect(value?.gender, Gender.female);
    });

    test('로그인되어 있지 않으면 AuthFailure로 매핑한다', () async {
      when(
        () => dataSource.fetchMine(),
      ).thenThrow(const AuthException('로그인이 필요해요.'));

      final result = await repository.getMyDemographics();

      expect((result as Err<Demographics?>).failure, isA<AuthFailure>());
    });

    test('PostgrestException은 ServerFailure로 매핑한다', () async {
      when(
        () => dataSource.fetchMine(),
      ).thenThrow(const PostgrestException(message: 'boom', code: '500'));

      final result = await repository.getMyDemographics();

      expect((result as Err<Demographics?>).failure, isA<ServerFailure>());
    });
  });

  group('saveDemographics', () {
    const demographics = Demographics(age: 72, gender: Gender.female);

    test('저장 성공', () async {
      when(
        () => dataSource.upsertMine(age: 72, gender: 'female'),
      ).thenAnswer((_) async {});

      final result = await repository.saveDemographics(demographics);

      expect(result, isA<Ok<void>>());
      verify(() => dataSource.upsertMine(age: 72, gender: 'female')).called(1);
    });

    test('권한 오류(RLS)는 AuthFailure로 매핑한다', () async {
      when(
        () => dataSource.upsertMine(age: 72, gender: 'female'),
      ).thenThrow(const PostgrestException(message: 'denied', code: '42501'));

      final result = await repository.saveDemographics(demographics);

      expect((result as Err<void>).failure, isA<AuthFailure>());
    });
  });
}
