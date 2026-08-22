import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/core/location/domain/entities/region.dart';
import 'package:ondam_senior/features/welfare_center/data/datasources/welfare_center_remote_datasource.dart';
import 'package:ondam_senior/features/welfare_center/data/repositories/welfare_center_repository_impl.dart';
import 'package:ondam_senior/features/welfare_center/domain/entities/senior_center.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockWelfareCenterRemoteDataSource extends Mock
    implements WelfareCenterRemoteDataSource {}

void main() {
  late _MockWelfareCenterRemoteDataSource dataSource;
  late WelfareCenterRepositoryImpl repository;
  const region = Region(sido: '서울특별시', sigungu: '강남구', dong: '역삼동');

  setUp(() {
    dataSource = _MockWelfareCenterRemoteDataSource();
    repository = WelfareCenterRepositoryImpl(dataSource);
  });

  test('정상 검색: 응답을 SeniorCenter 목록으로 변환하고 거리는 항상 null이다', () async {
    when(() => dataSource.search(region)).thenAnswer(
      (_) async => {
        'ok': true,
        'results': [
          {
            'id': '역삼경로당__서울특별시 강남구 역삼로 1',
            'name': '역삼경로당',
            'address': '서울특별시 강남구 역삼로 1',
            'phoneNumber': '02-1234-5678',
          },
        ],
      },
    );

    final result = await repository.search(region);

    expect(result, isA<Ok<List<SeniorCenter>>>());
    final value = (result as Ok<List<SeniorCenter>>).value;
    expect(value.length, 1);
    expect(value.first.name, '역삼경로당');
    expect(value.first.phoneNumber, '02-1234-5678');
    expect(value.first.distanceMeters, isNull);
  });

  test('결과 없음: 빈 목록을 정직하게 반환한다', () async {
    when(() => dataSource.search(region)).thenAnswer(
      (_) async => {'ok': true, 'results': <Map<String, dynamic>>[]},
    );

    final result = await repository.search(region);

    expect((result as Ok<List<SeniorCenter>>).value, isEmpty);
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
        (result as Err<List<SeniorCenter>>).failure,
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

    expect((result as Err<List<SeniorCenter>>).failure, isA<ServerFailure>());
  });

  test('잘못된 지역 값은 ValidationFailure로 매핑한다', () async {
    when(() => dataSource.search(region)).thenThrow(
      const FunctionException(
        status: 400,
        details: {'ok': false, 'reason': 'invalid_region'},
      ),
    );

    final result = await repository.search(region);

    expect(
      (result as Err<List<SeniorCenter>>).failure,
      isA<ValidationFailure>(),
    );
  });

  test('로그인되어 있지 않으면 AuthFailure로 매핑한다', () async {
    when(
      () => dataSource.search(region),
    ).thenThrow(const AuthException('로그인이 필요해요.'));

    final result = await repository.search(region);

    expect((result as Err<List<SeniorCenter>>).failure, isA<AuthFailure>());
  });
}
