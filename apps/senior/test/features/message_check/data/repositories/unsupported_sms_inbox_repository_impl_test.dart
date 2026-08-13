import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/features/message_check/data/repositories/unsupported_sms_inbox_repository_impl.dart';
import 'package:ondam_senior/features/message_check/domain/entities/sms_permission_status.dart';

void main() {
  const repository = UnsupportedSmsInboxRepositoryImpl();

  test('checkPermission always resolves to unsupported', () async {
    final result = await repository.checkPermission();

    expect(
      (result as Ok<SmsPermissionStatus>).value,
      SmsPermissionStatus.unsupported,
    );
  });

  test(
    'requestPermission always resolves to unsupported (never prompts)',
    () async {
      final result = await repository.requestPermission();

      expect(
        (result as Ok<SmsPermissionStatus>).value,
        SmsPermissionStatus.unsupported,
      );
    },
  );

  test(
    'fetchRecentMessages returns UnavailableFailure, never a fake list',
    () async {
      final result = await repository.fetchRecentMessages();

      expect(result, isA<Err<List<Object>>>());
    },
  );
}
