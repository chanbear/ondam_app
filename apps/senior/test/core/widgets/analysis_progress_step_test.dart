import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_senior/core/widgets/analysis_progress_step.dart';

/// ONDAM 2.0 요구사항 12/21 — 초기/중간/완료 상태가 올바른 순서와 값으로
/// 이어지는지, 그리고 마지막 단계를 넘어 100%로 가지 않는지 확인한다.
void main() {
  test('초기 상태(preparing)는 10%다', () {
    expect(AnalysisProgressStep.preparing.percent, 10);
  });

  test('단계는 preparing → sending → analyzing → finishing 순으로 진행된다', () {
    expect(AnalysisProgressStep.preparing.next, AnalysisProgressStep.sending);
    expect(AnalysisProgressStep.sending.next, AnalysisProgressStep.analyzing);
    expect(AnalysisProgressStep.analyzing.next, AnalysisProgressStep.finishing);
  });

  test('마지막 단계(finishing)는 90%이고 다음 단계가 없다 — 100%를 표시하지 않는다', () {
    expect(AnalysisProgressStep.finishing.percent, 90);
    expect(AnalysisProgressStep.finishing.next, isNull);
  });

  test('모든 단계의 퍼센트는 0~100 범위 안에 있다', () {
    for (final step in AnalysisProgressStep.values) {
      expect(step.percent, greaterThanOrEqualTo(0));
      expect(step.percent, lessThan(100));
    }
  });
}
