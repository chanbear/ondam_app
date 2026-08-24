import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/core/location/domain/entities/region.dart';
import 'package:ondam_senior/features/support/data/datasources/local_gov_office_remote_datasource.dart';
import 'package:ondam_senior/features/support/data/repositories/local_gov_office_repository_impl.dart';
import 'package:ondam_senior/features/support/domain/entities/local_gov_office.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockLocalGovOfficeRemoteDataSource extends Mock
    implements LocalGovOfficeRemoteDataSource {}

void main() {
  late _MockLocalGovOfficeRemoteDataSource dataSource;
  late LocalGovOfficeRepositoryImpl repository;
  const region = Region(sido: '서울특별시', sigungu: '강남구', dong: '역삼동');

  setUp(() {
    dataSource = _MockLocalGovOfficeRemoteDataSource();
    repository = LocalGovOfficeRepositoryImpl(dataSource);
  });

  test('정상 조회: 응답을 LocalGovOffice로 변환한다', () async {
    when(() => dataSource.search(region)).thenAnswer(
      (_) async => {
        'ok': true,
        'result': {
          'address': '서울특별시 강남구 테헤란로 지하 426',
          'postalCode': '06236',
          'phoneNumber': null,
        },
      },
    );

    final result = await repository.search(region);

    expect(result, isA<Ok<LocalGovOffice?>>());
    final value = (result as Ok<LocalGovOffice?>).value;
    expect(value!.address, '서울특별시 강남구 테헤란로 지하 426');
    expect(value.postalCode, '06236');
    expect(value.phoneNumber, isNull);
  });

  test('일치하는 기관 없음: null을 정직하게 반환한다', () async {
    when(
      () => dataSource.search(region),
    ).thenAnswer((_) async => {'ok': true, 'result': null});

    final result = await repository.search(region);

    expect((result as Ok<LocalGovOffice?>).value, isNull);
  });

  test(
    '데이터 소스가 아직 설정되지 않았으면(사용자가 서비스키 미등록) UnavailableFailure로 정직하게 안내한다',
    () async {
      when(() => dataSource.search(region)).thenThrow(
        const FunctionException(
          status: 503,
          details: {'ok': false, 'reason': 'data_source_not_configured'},
        ),
      );

      final result = await repository.search(region);

      expect(
        (result as Err<LocalGovOffice?>).failure,
        isA<UnavailableFailure>(),
      );
    },
  );

  test('업스트림(data.go.kr) 오류/타임아웃/잘못된 응답은 ServerFailure로 매핑한다', () async {
    when(() => dataSource.search(region)).thenThrow(
      const FunctionException(
        status: 502,
        details: {'ok': false, 'reason': 'upstream_error'},
      ),
    );

    final result = await repository.search(region);

    expect((result as Err<LocalGovOffice?>).failure, isA<ServerFailure>());
  });

  test('잘못된 지역 값은 ValidationFailure로 매핑한다', () async {
    when(() => dataSource.search(region)).thenThrow(
      const FunctionException(
        status: 400,
        details: {'ok': false, 'reason': 'invalid_region'},
      ),
    );

    final result = await repository.search(region);

    expect((result as Err<LocalGovOffice?>).failure, isA<ValidationFailure>());
  });

  test('로그인되어 있지 않으면 AuthFailure로 매핑한다', () async {
    when(
      () => dataSource.search(region),
    ).thenThrow(const AuthException('로그인이 필요해요.'));

    final result = await repository.search(region);

    expect((result as Err<LocalGovOffice?>).failure, isA<AuthFailure>());
  });
}
