import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/core/demographics/domain/entities/demographics.dart';
import 'package:ondam_senior/core/location/domain/entities/region.dart';
import 'package:ondam_senior/features/info/data/datasources/benefit_service_remote_datasource.dart';
import 'package:ondam_senior/features/info/data/repositories/benefit_service_repository_impl.dart';
import 'package:ondam_senior/features/info/domain/entities/benefit_service.dart';
import 'package:ondam_senior/features/info/domain/entities/benefit_service_detail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockBenefitServiceRemoteDataSource extends Mock
    implements BenefitServiceRemoteDataSource {}

void main() {
  late _MockBenefitServiceRemoteDataSource dataSource;
  late BenefitServiceRepositoryImpl repository;
  const demographics = Demographics(age: 72, gender: Gender.female);
  const region = Region(sido: '서울특별시', sigungu: '강남구', dong: '역삼동');

  setUp(() {
    dataSource = _MockBenefitServiceRemoteDataSource();
    repository = BenefitServiceRepositoryImpl(dataSource);
  });

  group('search', () {
    test('정상 검색: 응답을 BenefitService 목록으로 변환한다', () async {
      when(
        () => dataSource.search(age: 72, gender: 'female', region: region),
      ).thenAnswer(
        (_) async => {
          'ok': true,
          'results': [
            {
              'id': 'WLF001',
              'source': 'central',
              'title': '기초연금',
              'summary': '만 65세 이상 지원',
            },
          ],
        },
      );

      final result = await repository.search(demographics, region);

      final value = (result as Ok<List<BenefitService>>).value;
      expect(value.length, 1);
      expect(value.first.title, '기초연금');
      expect(value.first.source, BenefitServiceSource.central);
    });

    test('데이터 소스가 아직 설정되지 않았으면 UnavailableFailure로 정직하게 안내한다', () async {
      when(
        () => dataSource.search(age: 72, gender: 'female', region: region),
      ).thenThrow(
        const FunctionException(
          status: 503,
          details: {'ok': false, 'reason': 'data_source_not_configured'},
        ),
      );

      final result = await repository.search(demographics, region);

      expect(
        (result as Err<List<BenefitService>>).failure,
        isA<UnavailableFailure>(),
      );
    });

    test('로그인되어 있지 않으면 AuthFailure로 매핑한다', () async {
      when(
        () => dataSource.search(age: 72, gender: 'female', region: region),
      ).thenThrow(const AuthException('로그인이 필요해요.'));

      final result = await repository.search(demographics, region);

      expect((result as Err<List<BenefitService>>).failure, isA<AuthFailure>());
    });
  });

  group('getDetail', () {
    test('정상 조회: 응답을 BenefitServiceDetail로 변환한다', () async {
      when(
        () => dataSource.getDetail(id: 'WLF001', source: 'central'),
      ).thenAnswer(
        (_) async => {
          'ok': true,
          'result': {
            'id': 'WLF001',
            'title': '기초연금',
            'summary': '만 65세 이상 지원',
            'supportTarget': '소득 하위 70%',
            'applyMethod': '주민센터 방문 신청',
            'contact': '129',
            'externalUrl': null,
          },
        },
      );

      final result = await repository.getDetail(
        'WLF001',
        BenefitServiceSource.central,
      );

      final value = (result as Ok<BenefitServiceDetail>).value;
      expect(value.title, '기초연금');
      expect(value.contact, '129');
    });

    test('업스트림 오류는 ServerFailure로 매핑한다', () async {
      when(
        () => dataSource.getDetail(id: 'WLF001', source: 'central'),
      ).thenThrow(
        const FunctionException(
          status: 502,
          details: {'ok': false, 'reason': 'upstream_error'},
        ),
      );

      final result = await repository.getDetail(
        'WLF001',
        BenefitServiceSource.central,
      );

      expect(
        (result as Err<BenefitServiceDetail>).failure,
        isA<ServerFailure>(),
      );
    });
  });
}
