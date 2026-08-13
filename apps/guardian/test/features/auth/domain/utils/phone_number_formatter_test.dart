import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_guardian/features/auth/domain/utils/phone_number_formatter.dart';

void main() {
  group('toE164KoreanPhoneNumber', () {
    test('normalizes a 010-prefixed number with dashes', () {
      expect(toE164KoreanPhoneNumber('010-1234-5678'), '+821012345678');
    });

    test('normalizes a 010-prefixed number with spaces', () {
      expect(toE164KoreanPhoneNumber('010 1234 5678'), '+821012345678');
    });

    test('normalizes a number already in E.164 form', () {
      expect(toE164KoreanPhoneNumber('+821012345678'), '+821012345678');
    });

    test('accepts an 11-digit mobile number', () {
      expect(toE164KoreanPhoneNumber('01112345678'), '+821112345678');
    });

    test('rejects a non-mobile (landline-style) number', () {
      expect(toE164KoreanPhoneNumber('02-1234-5678'), isNull);
    });

    test('rejects too-short input', () {
      expect(toE164KoreanPhoneNumber('010-123'), isNull);
    });

    test('rejects non-numeric garbage', () {
      expect(toE164KoreanPhoneNumber('phone-number'), isNull);
    });
  });
}
