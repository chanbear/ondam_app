import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';
import 'package:ondam_senior/features/document_scan/data/datasources/analysis_remote_datasource.dart';
import 'package:ondam_senior/features/document_scan/data/repositories/analysis_repository_impl.dart';
import 'package:ondam_senior/features/document_scan/domain/entities/captured_photo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockAnalysisRemoteDataSource extends Mock
    implements AnalysisRemoteDataSource {}

void main() {
  late _MockAnalysisRemoteDataSource dataSource;
  late AnalysisRepositoryImpl repository;
  final photo = CapturedPhoto(
    localPath: '/tmp/photo.jpg',
    capturedAt: DateTime(2026, 1, 1),
  );

  setUp(() {
    dataSource = _MockAnalysisRemoteDataSource();
    repository = AnalysisRepositoryImpl(dataSource);
  });

  test('유효한 응답이면 AnalysisResult로 변환해 Ok를 반환한다', () async {
    when(() => dataSource.analyzeDocument(photo)).thenAnswer(
      (_) async => {
        'ok': true,
        'id': 'a1',
        'elderId': 'e1',
        'type': 'document',
        'riskLevel': null,
        'summary': '전기요금 고지서예요. 8월 25일까지 32,000원을 납부해야 해요.',
        'sourceExcerpt': null,
        'reliability': 'high',
        'structuredFields': {'금액': '32,000원', '납부기한': '2026-08-25'},
        'createdAt': '2026-01-01T00:00:00.000Z',
      },
    );

    final result = await repository.analyzeDocument(photo);

    expect(result, isA<Ok<AnalysisResult>>());
    final value = (result as Ok<AnalysisResult>).value;
    expect(value.type, AnalysisType.document);
    expect(value.riskLevel, isNull);
    expect(value.reliability, ReliabilityLevel.high);
    expect(value.structuredFields, {'금액': '32,000원', '납부기한': '2026-08-25'});
  });

  test('data.ok가 false면(예: server_error) 성공으로 오인하지 않고 Failure를 반환한다', () async {
    when(
      () => dataSource.analyzeDocument(photo),
    ).thenAnswer((_) async => {'ok': false, 'reason': 'server_error'});

    final result = await repository.analyzeDocument(photo);

    expect(result, isA<Err<AnalysisResult>>());
    expect((result as Err<AnalysisResult>).failure, isA<ServerFailure>());
  });

  test(
    'FunctionException(ai_provider_not_configured)는 UnavailableFailure로 매핑한다 — '
    'AI provider 미설정을 서버 오류와 구분',
    () async {
      when(() => dataSource.analyzeDocument(photo)).thenThrow(
        const FunctionException(
          status: 503,
          details: {'ok': false, 'reason': 'ai_provider_not_configured'},
        ),
      );

      final result = await repository.analyzeDocument(photo);

      expect(
        (result as Err<AnalysisResult>).failure,
        isA<UnavailableFailure>(),
      );
    },
  );

  test(
    'FunctionException(invalid_storage_path)는 ValidationFailure로 매핑한다',
    () async {
      when(() => dataSource.analyzeDocument(photo)).thenThrow(
        const FunctionException(
          status: 400,
          details: {'ok': false, 'reason': 'invalid_storage_path'},
        ),
      );

      final result = await repository.analyzeDocument(photo);

      expect((result as Err<AnalysisResult>).failure, isA<ValidationFailure>());
    },
  );

  test(
    'AI provider 실패/timeout/malformed 응답/storage 다운로드 실패는 ServerFailure로 매핑한다',
    () async {
      for (final reason in [
        'ai_provider_error',
        'ai_provider_timeout',
        'ai_response_invalid',
        'storage_download_failed',
      ]) {
        when(() => dataSource.analyzeDocument(photo)).thenThrow(
          FunctionException(
            status: 502,
            details: {'ok': false, 'reason': reason},
          ),
        );

        final result = await repository.analyzeDocument(photo);

        expect(
          (result as Err<AnalysisResult>).failure,
          isA<ServerFailure>(),
          reason: 'reason=$reason should map to ServerFailure',
        );
      }
    },
  );

  test('Storage 업로드 실패(StorageException)는 ServerFailure로 매핑한다', () async {
    when(
      () => dataSource.analyzeDocument(photo),
    ).thenThrow(const StorageException('upload failed'));

    final result = await repository.analyzeDocument(photo);

    expect((result as Err<AnalysisResult>).failure, isA<ServerFailure>());
  });

  test('로그인되어 있지 않으면(AuthException) AuthFailure로 매핑한다', () async {
    when(
      () => dataSource.analyzeDocument(photo),
    ).thenThrow(const AuthException('로그인이 필요해요.'));

    final result = await repository.analyzeDocument(photo);

    expect((result as Err<AnalysisResult>).failure, isA<AuthFailure>());
  });

  test('필수 필드가 빠진 malformed 응답은 크래시하지 않고 UnknownFailure로 안전하게 처리한다', () async {
    when(
      () => dataSource.analyzeDocument(photo),
    ).thenAnswer((_) async => {'ok': true});

    final result = await repository.analyzeDocument(photo);

    expect((result as Err<AnalysisResult>).failure, isA<UnknownFailure>());
  });
}
