import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';
import 'package:ondam_senior/features/analysis/data/datasources/analysis_records_remote_datasource.dart';
import 'package:ondam_senior/features/analysis/data/repositories/analysis_records_repository_impl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockAnalysisRecordsRemoteDataSource extends Mock
    implements AnalysisRecordsRemoteDataSource {}

void main() {
  late _MockAnalysisRecordsRemoteDataSource dataSource;
  late AnalysisRecordsRepositoryImpl repository;

  setUp(() {
    dataSource = _MockAnalysisRecordsRemoteDataSource();
    repository = AnalysisRecordsRepositoryImpl(dataSource);
  });

  test('DB row 목록을 AnalysisResult 목록으로 변환해 Ok를 반환한다', () async {
    when(() => dataSource.fetchMine()).thenAnswer(
      (_) async => [
        {
          'id': 'a1',
          'elder_id': 'e1',
          'type': 'document',
          'reliability': 'high',
          'summary': '전기요금 고지서예요.',
          'created_at': '2026-08-01T00:00:00.000Z',
          'risk_level': 'caution',
          'source_excerpt': null,
          'structured_fields': {'금액': '32,000원'},
        },
        {
          'id': 'a2',
          'elder_id': 'e1',
          'type': 'message',
          'reliability': 'low',
          'summary': '광고성 문자예요.',
          'created_at': '2026-08-02T00:00:00.000Z',
          'risk_level': null,
          'source_excerpt': null,
          'structured_fields': null,
        },
      ],
    );

    final result = await repository.getMyRecords();

    expect(result, isA<Ok<List<AnalysisResult>>>());
    final records = (result as Ok<List<AnalysisResult>>).value;
    expect(records, hasLength(2));
    expect(records[0].type, AnalysisType.document);
    expect(records[0].riskLevel, RiskLevel.caution);
    expect(records[0].reliability, ReliabilityLevel.high);
    expect(records[0].structuredFields, {'금액': '32,000원'});
    expect(records[0].createdAt, DateTime.parse('2026-08-01T00:00:00.000Z'));
    expect(records[1].type, AnalysisType.message);
    expect(records[1].riskLevel, isNull);
  });

  test('빈 목록도 에러가 아니라 Ok(빈 리스트)로 반환한다', () async {
    when(() => dataSource.fetchMine()).thenAnswer((_) async => []);

    final result = await repository.getMyRecords();

    expect(result, isA<Ok<List<AnalysisResult>>>());
    expect((result as Ok<List<AnalysisResult>>).value, isEmpty);
  });

  test('로그인되어 있지 않으면(AuthException) AuthFailure로 매핑한다', () async {
    when(
      () => dataSource.fetchMine(),
    ).thenThrow(const AuthException('로그인이 필요해요.'));

    final result = await repository.getMyRecords();

    expect((result as Err<List<AnalysisResult>>).failure, isA<AuthFailure>());
  });

  test('RLS 위반(PostgrestException 42501)은 AuthFailure로 매핑한다', () async {
    when(
      () => dataSource.fetchMine(),
    ).thenThrow(const PostgrestException(message: 'denied', code: '42501'));

    final result = await repository.getMyRecords();

    expect((result as Err<List<AnalysisResult>>).failure, isA<AuthFailure>());
  });

  test('그 외 PostgrestException은 ServerFailure로 매핑한다', () async {
    when(
      () => dataSource.fetchMine(),
    ).thenThrow(const PostgrestException(message: 'db error', code: '500'));

    final result = await repository.getMyRecords();

    expect((result as Err<List<AnalysisResult>>).failure, isA<ServerFailure>());
  });

  test('예상치 못한 예외는 UnknownFailure로 안전하게 처리한다', () async {
    when(() => dataSource.fetchMine()).thenThrow(Exception('boom'));

    final result = await repository.getMyRecords();

    expect(
      (result as Err<List<AnalysisResult>>).failure,
      isA<UnknownFailure>(),
    );
  });

  group('confirm — 확인 완료 저장', () {
    test('성공하면 Ok를 반환한다', () async {
      when(() => dataSource.confirm('a1')).thenAnswer((_) async {});

      final result = await repository.confirm('a1');

      expect(result, isA<Ok<void>>());
      verify(() => dataSource.confirm('a1')).called(1);
    });

    test('RLS 위반(다른 사람의 기록)은 AuthFailure로 매핑한다', () async {
      when(
        () => dataSource.confirm('other'),
      ).thenThrow(const PostgrestException(message: 'denied', code: '42501'));

      final result = await repository.confirm('other');

      expect((result as Err<void>).failure, isA<AuthFailure>());
    });

    test('네트워크 등 예상치 못한 예외는 UnknownFailure로 처리한다', () async {
      when(() => dataSource.confirm('a1')).thenThrow(Exception('boom'));

      final result = await repository.confirm('a1');

      expect((result as Err<void>).failure, isA<UnknownFailure>());
    });
  });
}
