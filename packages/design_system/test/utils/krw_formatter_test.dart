import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

void main() {
  group('formatKrw', () {
    test('천 단위 콤마와 "원"을 붙인다', () {
      expect(formatKrw(87500), '87,500원');
    });

    test('1000 미만은 콤마 없이 표시한다', () {
      expect(formatKrw(500), '500원');
    });

    test('0은 "0원"으로 표시한다', () {
      expect(formatKrw(0), '0원');
    });
  });

  group('formatKrwCompact', () {
    test('만원 단위는 "만"으로 축약한다', () {
      expect(formatKrwCompact(87500), '8.8만');
    });

    test('억원 단위는 "억"으로 축약한다', () {
      expect(formatKrwCompact(150000000), '1.5억');
    });

    test('만원 미만은 그대로 표시한다', () {
      expect(formatKrwCompact(5000), '5000');
    });

    test('아주 큰 금액도 예외 없이 짧은 억 단위 문자열로 축약된다', () {
      final result = formatKrwCompact(999999999999);
      expect(result.length, lessThan(10));
      expect(result.endsWith('억'), isTrue);
    });
  });
}
