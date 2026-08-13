import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_senior/features/message_check/data/repositories/sms_inbox_repository_factory.dart';
import 'package:ondam_senior/features/message_check/data/repositories/unsupported_sms_inbox_repository_impl.dart';

void main() {
  test(
    'on this test host (not Android), the factory resolves to the unsupported/manual-input implementation',
    () {
      // `flutter test` runs as a plain Dart VM process on the host OS, not
      // inside an Android runtime, so `Platform.isAndroid` is always false
      // here — this test documents/locks in that the factory degrades
      // safely rather than crashing or guessing.
      final repository = createSmsInboxRepository();

      expect(repository, isA<UnsupportedSmsInboxRepositoryImpl>());
    },
  );
}
