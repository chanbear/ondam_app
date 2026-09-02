import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';
import 'package:ondam_senior/features/message_check/data/datasources/message_risk_remote_datasource.dart';
import 'package:ondam_senior/features/message_check/data/repositories/message_risk_repository_impl.dart';
import 'package:ondam_senior/features/message_check/domain/entities/sms_message.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockMessageRiskRemoteDataSource extends Mock
    implements MessageRiskRemoteDataSource {}

void main() {
  late _MockMessageRiskRemoteDataSource dataSource;
  late MessageRiskRepositoryImpl repository;
  final message = SmsMessage(
    sender: '010-1234-5678',
    body: '[Web발신] 계좌가 정지되었습니다. 즉시 확인 바랍니다.',
    receivedAt: DateTime(2026, 1, 1),
  );

  setUp(() {
    dataSource = _MockMessageRiskRemoteDataSource();
    repository = MessageRiskRepositoryImpl(dataSource);
  });

  test('유효한 응답이면 AnalysisResult로 변환해 Ok를 반환한다', () async {
    when(() => dataSource.analyzeMessage(message.body, any())).thenAnswer(
      (_) async => {
        'ok': true,
        'id': 'a1',
        'elderId': 'e1',
        'type': 'message',
        'riskLevel': 'dangerous',
        'summary': '계좌 정지를 빙자한 전형적인 스미싱 문자예요.',
        'sourceExcerpt': message.body,
        'reliability': 'high',
        'structuredFields': {'riskType': 'smishing'},
        'createdAt': '2026-01-01T00:00:00.000Z',
        'notifiedGuardianCount': 1,
      },
    );

    final result = await repository.analyzeMessage(message, 'ko');

    expect(result, isA<Ok<AnalysisResult>>());
    final value = (result as Ok<AnalysisResult>).value;
    expect(value.riskLevel, RiskLevel.dangerous);
    expect(value.reliability, ReliabilityLevel.high);
    expect(value.type, AnalysisType.message);
    expect(value.structuredFields, {'riskType': 'smishing'});
    // Phase 3(ONDAM 2.0): actionItems/importantDates/clarifyingQuestions 키가
    // 아예 없는 기존 응답도 크래시 없이 null로 처리돼야 한다(하위 호환).
    expect(value.actionItems, isNull);
    expect(value.importantDates, isNull);
    expect(value.clarifyingQuestions, isNull);
  });

  test(
    'Phase 3: actionItems/importantDates가 응답에 있으면 AnalysisResult까지 정상 전달된다',
    () async {
      when(() => dataSource.analyzeMessage(message.body, any())).thenAnswer(
        (_) async => {
          'ok': true,
          'id': 'a2',
          'elderId': 'e1',
          'type': 'message',
          'riskLevel': 'caution',
          'summary': '환급금을 빙자해 개인정보를 요구하는 문자예요.',
          'sourceExcerpt': message.body,
          'reliability': 'medium',
          'structuredFields': {'riskType': 'other_scam'},
          'actionItems': [
            {'id': 'ai1', 'title': '발신 번호로 다시 연락하지 않기', 'completed': false},
          ],
          'clarifyingQuestions': ['이 번호로 실제 거래를 한 적이 있나요?'],
          'createdAt': '2026-01-01T00:00:00.000Z',
          'notifiedGuardianCount': 0,
        },
      );

      final result = await repository.analyzeMessage(message, 'ko');

      expect(result, isA<Ok<AnalysisResult>>());
      final value = (result as Ok<AnalysisResult>).value;
      // riskLevel=caution + reliability=medium — 서로 강제되는 관계가 아님을 확인.
      expect(value.riskLevel, RiskLevel.caution);
      expect(value.reliability, ReliabilityLevel.medium);
      expect(value.actionItems, hasLength(1));
      expect(value.actionItems!.single.title, '발신 번호로 다시 연락하지 않기');
      expect(value.clarifyingQuestions, ['이 번호로 실제 거래를 한 적이 있나요?']);
      expect(value.importantDates, isNull);
    },
  );

  test('data.ok가 false면(예: server_error) 성공으로 오인하지 않고 Failure를 반환한다', () async {
    when(
      () => dataSource.analyzeMessage(message.body, any()),
    ).thenAnswer((_) async => {'ok': false, 'reason': 'server_error'});

    final result = await repository.analyzeMessage(message, 'ko');

    expect(result, isA<Err<AnalysisResult>>());
    expect((result as Err<AnalysisResult>).failure, isA<ServerFailure>());
  });

  test(
    'FunctionException(ai_provider_not_configured)는 UnavailableFailure로 매핑한다 — '
    'AI provider 미설정을 서버 오류와 구분',
    () async {
      when(() => dataSource.analyzeMessage(message.body, any())).thenThrow(
        const FunctionException(
          status: 503,
          details: {'ok': false, 'reason': 'ai_provider_not_configured'},
        ),
      );

      final result = await repository.analyzeMessage(message, 'ko');

      expect(
        (result as Err<AnalysisResult>).failure,
        isA<UnavailableFailure>(),
      );
    },
  );

  test('FunctionException(invalid_message)는 ValidationFailure로 매핑한다', () async {
    when(() => dataSource.analyzeMessage(message.body, any())).thenThrow(
      const FunctionException(
        status: 400,
        details: {'ok': false, 'reason': 'invalid_message'},
      ),
    );

    final result = await repository.analyzeMessage(message, 'ko');

    expect((result as Err<AnalysisResult>).failure, isA<ValidationFailure>());
  });

  test(
    'AI provider 실패(ai_provider_error)/timeout/malformed AI 응답은 ServerFailure로 매핑한다',
    () async {
      for (final reason in [
        'ai_provider_error',
        'ai_provider_timeout',
        'ai_response_invalid',
      ]) {
        when(() => dataSource.analyzeMessage(message.body, any())).thenThrow(
          FunctionException(
            status: 502,
            details: {'ok': false, 'reason': reason},
          ),
        );

        final result = await repository.analyzeMessage(message, 'ko');

        expect(
          (result as Err<AnalysisResult>).failure,
          isA<ServerFailure>(),
          reason: 'reason=$reason should map to ServerFailure',
        );
      }
    },
  );

  test('필수 필드가 빠진 malformed 응답은 크래시하지 않고 UnknownFailure로 안전하게 처리한다', () async {
    when(
      () => dataSource.analyzeMessage(message.body, any()),
    ).thenAnswer((_) async => {'ok': true});

    final result = await repository.analyzeMessage(message, 'ko');

    expect((result as Err<AnalysisResult>).failure, isA<UnknownFailure>());
  });

  test('notifyGuardian: 성공 응답이면 Ok를 반환한다', () async {
    when(
      () =>
          dataSource.notifyGuardian(targetUserId: 'g1', analysisResultId: 'a1'),
    ).thenAnswer((_) async => {'ok': true, 'notificationId': 'n1'});

    final result = await repository.notifyGuardian(
      targetUserId: 'g1',
      analysisResultId: 'a1',
    );

    expect(result, isA<Ok<void>>());
  });

  test('notifyGuardian: not_linked이면 실패로 처리한다(가짜 성공 금지)', () async {
    when(
      () =>
          dataSource.notifyGuardian(targetUserId: 'g1', analysisResultId: 'a1'),
    ).thenAnswer((_) async => {'ok': false, 'reason': 'not_linked'});

    final result = await repository.notifyGuardian(
      targetUserId: 'g1',
      analysisResultId: 'a1',
    );

    expect(result, isA<Err<void>>());
  });

  test('notifyGuardian: FunctionException은 UnknownFailure로 매핑한다', () async {
    when(
      () =>
          dataSource.notifyGuardian(targetUserId: 'g1', analysisResultId: 'a1'),
    ).thenThrow(
      const FunctionException(status: 500, details: {'reason': 'server_error'}),
    );

    final result = await repository.notifyGuardian(
      targetUserId: 'g1',
      analysisResultId: 'a1',
    );

    expect((result as Err<void>).failure, isA<ServerFailure>());
  });
}
