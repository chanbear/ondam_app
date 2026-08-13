import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_guardian/features/analysis/domain/risk_summary.dart';
import 'package:ondam_models/ondam_models.dart';

AnalysisResult _record({RiskLevel? riskLevel}) {
  return AnalysisResult(
    id: 'r',
    elderId: 'e1',
    type: AnalysisType.message,
    reliability: ReliabilityLevel.high,
    summary: 's',
    createdAt: DateTime(2026, 1, 1),
    riskLevel: riskLevel,
  );
}

void main() {
  test('빈 목록이면 null(안심 상태 기본값)을 반환한다', () {
    expect(RiskSummary.worst(const []), isNull);
  });

  test('risk가 전부 null(문서형)이면 null을 반환한다', () {
    final records = [_record(), _record()];
    expect(RiskSummary.worst(records), isNull);
  });

  test('가장 심각한 위험도를 반환한다(dangerous > caution > safe)', () {
    final records = [
      _record(riskLevel: RiskLevel.safe),
      _record(riskLevel: RiskLevel.dangerous),
      _record(riskLevel: RiskLevel.caution),
    ];
    expect(RiskSummary.worst(records), RiskLevel.dangerous);
  });

  test('전부 safe이면 safe를 반환한다', () {
    final records = [_record(riskLevel: RiskLevel.safe)];
    expect(RiskSummary.worst(records), RiskLevel.safe);
  });
}
