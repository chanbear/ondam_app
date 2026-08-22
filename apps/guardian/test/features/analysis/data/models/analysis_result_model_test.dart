import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_guardian/features/analysis/data/models/analysis_result_model.dart';

void main() {
  test(
    'billing_amount_krw/billing_date가 있으면 그대로 파싱된다 — 요금 통계(PHASE 37)의 원천 데이터',
    () {
      final model = AnalysisResultModel.fromJson({
        'id': 'a1',
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
      'id': 'a2',
      'elder_id': 'e1',
      'type': 'document',
      'reliability': 'medium',
      'summary': '요약',
      'created_at': '2026-08-01T00:00:00.000Z',
    });

    final entity = model.toEntity();

    expect(entity.billingAmountKrw, isNull);
    expect(entity.billingDate, isNull);
  });
}
