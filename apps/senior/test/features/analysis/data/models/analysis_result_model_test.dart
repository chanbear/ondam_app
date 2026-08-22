import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_models/ondam_models.dart';
import 'package:ondam_senior/features/analysis/data/models/analysis_result_model.dart';

void main() {
  test('DB row의 모든 필드를 AnalysisResult로 정확히 변환한다', () {
    final model = AnalysisResultModel.fromJson({
      'id': 'a1',
      'elder_id': 'e1',
      'type': 'document',
      'reliability': 'high',
      'summary': '전기요금 고지서예요.',
      'created_at': '2026-08-01T09:30:00.000Z',
      'risk_level': 'caution',
      'source_excerpt': '원문 일부',
      'structured_fields': {'금액': '32,000원'},
    });

    final entity = model.toEntity();

    expect(entity.id, 'a1');
    expect(entity.elderId, 'e1');
    expect(entity.type, AnalysisType.document);
    expect(entity.reliability, ReliabilityLevel.high);
    expect(entity.summary, '전기요금 고지서예요.');
    expect(entity.createdAt, DateTime.parse('2026-08-01T09:30:00.000Z'));
    expect(entity.riskLevel, RiskLevel.caution);
    expect(entity.sourceExcerpt, '원문 일부');
    expect(entity.structuredFields, {'금액': '32,000원'});
    expect(entity.confirmedAt, isNull);
  });

  test('confirmed_at이 있으면 그대로 파싱된다 — 확인 완료 상태가 기록을 다시 열어도 유지된다', () {
    final model = AnalysisResultModel.fromJson({
      'id': 'a4',
      'elder_id': 'e1',
      'type': 'document',
      'reliability': 'high',
      'summary': '요약',
      'created_at': '2026-08-01T00:00:00.000Z',
      'confirmed_at': '2026-08-02T10:00:00.000Z',
    });

    final entity = model.toEntity();

    expect(entity.confirmedAt, DateTime.parse('2026-08-02T10:00:00.000Z'));
  });

  test('message 타입 + risk_level null인 row도 정상 변환된다', () {
    final model = AnalysisResultModel.fromJson({
      'id': 'a2',
      'elder_id': 'e1',
      'type': 'message',
      'reliability': 'low',
      'summary': '광고성 문자예요.',
      'created_at': '2026-08-02T00:00:00.000Z',
      'risk_level': null,
      'source_excerpt': null,
      'structured_fields': null,
    });

    final entity = model.toEntity();

    expect(entity.type, AnalysisType.message);
    expect(entity.riskLevel, isNull);
    expect(entity.structuredFields, isNull);
  });

  test('action_items/important_dates/clarifying_questions 컬럼이 없어도 '
      'null로 안전하게 처리된다 — DB에 persist되지 않는 세션 전용 필드', () {
    final model = AnalysisResultModel.fromJson({
      'id': 'a3',
      'elder_id': 'e1',
      'type': 'document',
      'reliability': 'medium',
      'summary': '요약',
      'created_at': '2026-08-03T00:00:00.000Z',
    });

    final entity = model.toEntity();

    expect(entity.actionItems, isNull);
    expect(entity.importantDates, isNull);
    expect(entity.clarifyingQuestions, isNull);
  });

  test(
    'billing_amount_krw/billing_date가 있으면 그대로 파싱된다 — 요금 통계(PHASE 37)의 원천 데이터',
    () {
      final model = AnalysisResultModel.fromJson({
        'id': 'a5',
        'elder_id': 'e1',
        'type': 'document',
        'reliability': 'high',
        'summary': '전기요금 고지서예요.',
        'created_at': '2026-08-01T00:00:00.000Z',
        'billing_amount_krw': 32000,
        'billing_date': '2026-08-25',
      });

      final entity = model.toEntity();

      expect(entity.billingAmountKrw, 32000);
      expect(entity.billingDate, DateTime.parse('2026-08-25'));
    },
  );

  test('billing_amount_krw/billing_date가 null이면 통계에서 제외될 수 있도록 null로 남는다', () {
    final model = AnalysisResultModel.fromJson({
      'id': 'a6',
      'elder_id': 'e1',
      'type': 'document',
      'reliability': 'medium',
      'summary': '요약',
      'created_at': '2026-08-01T00:00:00.000Z',
      'billing_amount_krw': null,
      'billing_date': null,
    });

    final entity = model.toEntity();

    expect(entity.billingAmountKrw, isNull);
    expect(entity.billingDate, isNull);
  });
}
