import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_design_system/ondam_design_system.dart';
import 'package:ondam_models/ondam_models.dart';

/// ONDAM 2.0 요구사항 13/22 — reliability(high/medium/low)를 표시용
/// 퍼센트로 매핑하는 규칙. 실제 AI 확률이 아니라는 점은 위젯의 doc
/// comment에 별도로 명시되어 있다 — 이 테스트는 매핑값 자체만 검증한다.
void main() {
  test('high는 90%로 매핑된다', () {
    expect(ReliabilityLevel.high.displayPercent, 90);
  });

  test('medium은 70%로 매핑된다', () {
    expect(ReliabilityLevel.medium.displayPercent, 70);
  });

  test('low는 40%로 매핑된다', () {
    expect(ReliabilityLevel.low.displayPercent, 40);
  });
}
