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
    when(() => dataSource.analyzeDocument(photo, any())).thenAnswer(
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

    final result = await repository.analyzeDocument(photo, 'ko');

    expect(result, isA<Ok<AnalysisResult>>());
    final value = (result as Ok<AnalysisResult>).value;
    expect(value.type, AnalysisType.document);
    expect(value.riskLevel, isNull);
    expect(value.reliability, ReliabilityLevel.high);
    expect(value.structuredFields, {'금액': '32,000원', '납부기한': '2026-08-25'});
    // Phase 3(ONDAM 2.0): actionItems/importantDates/clarifyingQuestions 키가
    // 아예 없는 기존 응답도 크래시 없이 null로 처리돼야 한다(하위 호환).
    expect(value.actionItems, isNull);
    expect(value.importantDates, isNull);
    expect(value.clarifyingQuestions, isNull);
  });

  test('Phase 3: actionItems/importantDates/clarifyingQuestions가 응답에 있으면 '
      'AnalysisResult까지 정상 전달된다', () async {
    when(() => dataSource.analyzeDocument(photo, any())).thenAnswer(
      (_) async => {
        'ok': true,
        'id': 'a3',
        'elderId': 'e1',
        'type': 'document',
        'riskLevel': 'safe',
        'summary': '관리비 고지서예요.',
        'sourceExcerpt': null,
        'reliability': 'low',
        'structuredFields': {'금액': '32,000원'},
        'actionItems': [
          {'id': 'ai1', 'title': '8월 25일까지 관리비 납부', 'completed': false},
        ],
        'importantDates': [
          {
            'date': '2026-08-25T00:00:00.000Z',
            'kind': 'paymentDue',
            'label': '관리비 납부기한',
            'priority': 'high',
            'needsSourceEvidence': true,
          },
        ],
        'clarifyingQuestions': ['이 고지서가 본인 명의 세대의 것이 맞나요?'],
        'createdAt': '2026-01-01T00:00:00.000Z',
      },
    );

    final result = await repository.analyzeDocument(photo, 'ko');

    expect(result, isA<Ok<AnalysisResult>>());
    final value = (result as Ok<AnalysisResult>).value;
    // riskLevel=safe + reliability=low — 서로 강제되는 관계가 아님을 함께 확인.
    expect(value.riskLevel, RiskLevel.safe);
    expect(value.reliability, ReliabilityLevel.low);

    expect(value.actionItems, hasLength(1));
    expect(value.actionItems!.single.id, 'ai1');
    expect(value.actionItems!.single.title, '8월 25일까지 관리비 납부');
    expect(value.actionItems!.single.completed, isFalse);

    expect(value.importantDates, hasLength(1));
    final date = value.importantDates!.single;
    expect(date.date, DateTime.parse('2026-08-25T00:00:00.000Z'));
    expect(date.kind, ImportantDateKind.paymentDue);
    expect(date.label, '관리비 납부기한');
    expect(date.priority, ImportantDatePriority.high);
    expect(date.needsSourceEvidence, isTrue);

    expect(value.clarifyingQuestions, ['이 고지서가 본인 명의 세대의 것이 맞나요?']);
  });

  test(
    'Phase 2: Edge Function 응답의 riskLevel이 AnalysisResult까지 그대로 전달된다',
    () async {
      when(() => dataSource.analyzeDocument(photo, any())).thenAnswer(
        (_) async => {
          'ok': true,
          'id': 'a2',
          'elderId': 'e1',
          'type': 'document',
          'riskLevel': 'caution',
          'summary': '금전 요구와 개인정보 요구가 함께 발견된 문서예요.',
          'sourceExcerpt': null,
          'reliability': 'medium',
          'structuredFields': {'금액': '500,000원'},
          'createdAt': '2026-01-01T00:00:00.000Z',
        },
      );

      final result = await repository.analyzeDocument(photo, 'ko');

      expect(result, isA<Ok<AnalysisResult>>());
      final value = (result as Ok<AnalysisResult>).value;
      expect(value.riskLevel, RiskLevel.caution);
      // confidence(reliability)와 riskLevel은 독립적으로 유지되어야 한다.
      expect(value.reliability, ReliabilityLevel.medium);
    },
  );

  test('data.ok가 false면(예: server_error) 성공으로 오인하지 않고 Failure를 반환한다', () async {
    when(
      () => dataSource.analyzeDocument(photo, any()),
    ).thenAnswer((_) async => {'ok': false, 'reason': 'server_error'});

    final result = await repository.analyzeDocument(photo, 'ko');

    expect(result, isA<Err<AnalysisResult>>());
    expect((result as Err<AnalysisResult>).failure, isA<ServerFailure>());
  });

  test(
    'FunctionException(ai_provider_not_configured)는 UnavailableFailure로 매핑한다 — '
    'AI provider 미설정을 서버 오류와 구분',
    () async {
      when(() => dataSource.analyzeDocument(photo, any())).thenThrow(
        const FunctionException(
          status: 503,
          details: {'ok': false, 'reason': 'ai_provider_not_configured'},
        ),
      );

      final result = await repository.analyzeDocument(photo, 'ko');

      expect(
        (result as Err<AnalysisResult>).failure,
        isA<UnavailableFailure>(),
      );
    },
  );

  test(
    'FunctionException(invalid_storage_path)는 ValidationFailure로 매핑한다',
    () async {
      when(() => dataSource.analyzeDocument(photo, any())).thenThrow(
        const FunctionException(
          status: 400,
          details: {'ok': false, 'reason': 'invalid_storage_path'},
        ),
      );

      final result = await repository.analyzeDocument(photo, 'ko');

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
        when(() => dataSource.analyzeDocument(photo, any())).thenThrow(
          FunctionException(
            status: 502,
            details: {'ok': false, 'reason': reason},
          ),
        );

        final result = await repository.analyzeDocument(photo, 'ko');

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
      () => dataSource.analyzeDocument(photo, any()),
    ).thenThrow(const StorageException('upload failed'));

    final result = await repository.analyzeDocument(photo, 'ko');

    expect((result as Err<AnalysisResult>).failure, isA<ServerFailure>());
  });

  test('로그인되어 있지 않으면(AuthException) AuthFailure로 매핑한다', () async {
    when(
      () => dataSource.analyzeDocument(photo, any()),
    ).thenThrow(const AuthException('로그인이 필요해요.'));

    final result = await repository.analyzeDocument(photo, 'ko');

    expect((result as Err<AnalysisResult>).failure, isA<AuthFailure>());
  });

  test('필수 필드가 빠진 malformed 응답은 크래시하지 않고 UnknownFailure로 안전하게 처리한다', () async {
    when(
      () => dataSource.analyzeDocument(photo, any()),
    ).thenAnswer((_) async => {'ok': true});

    final result = await repository.analyzeDocument(photo, 'ko');

    expect((result as Err<AnalysisResult>).failure, isA<UnknownFailure>());
  });
}
