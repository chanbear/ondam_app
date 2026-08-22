import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_senior/core/widgets/analysis_key_point_section.dart';

/// ONDAM 2.0 요구사항 14/23 — "주요 내용"은 AI 요약 전체가 아니라 첫
/// 문장만 짧게 보여줘야 한다.
void main() {
  test('여러 문장이면 첫 문장만 추출한다', () {
    expect(
      extractKeyPoint('신한투자증권을 사칭하는 메시지입니다. 인증번호를 절대 알려주지 마세요.'),
      '신한투자증권을 사칭하는 메시지입니다.',
    );
  });

  test('문장 구분이 없으면(짧은 문장) 전체를 그대로 반환한다', () {
    expect(extractKeyPoint('전기요금 고지서예요.'), '전기요금 고지서예요.');
  });

  test('빈 문자열이면 빈 문자열을 반환한다', () {
    expect(extractKeyPoint(''), '');
    expect(extractKeyPoint('   '), '');
  });

  test('첫 문장도 너무 길면 60자에서 잘라 말줄임표를 붙인다', () {
    final longSentence = '가' * 100;
    final result = extractKeyPoint('$longSentence 두번째 문장입니다.');
    expect(result.length, lessThanOrEqualTo(63)); // 60자 + '...'
    expect(result.endsWith('...'), isTrue);
  });
}
