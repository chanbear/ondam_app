import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/features/message_check/domain/entities/sms_permission_status.dart';
import 'package:ondam_senior/features/message_check/domain/usecases/check_sms_permission_usecase.dart';
import 'package:ondam_senior/features/message_check/domain/usecases/request_sms_permission_usecase.dart';

import '../fakes/fake_sms_inbox_repository.dart';

void main() {
  late FakeSmsInboxRepository repository;

  setUp(() {
    repository = FakeSmsInboxRepository();
  });

  group('CheckSmsPermissionUseCase', () {
    test('returns granted when the repository reports granted', () async {
      repository.checkResult = const Ok(SmsPermissionStatus.granted);
      final useCase = CheckSmsPermissionUseCase(repository);

      final result = await useCase();

      expect(
        (result as Ok<SmsPermissionStatus>).value,
        SmsPermissionStatus.granted,
      );
      expect(repository.checkCalls, 1);
    });

    test('returns unsupported without prompting the OS (e.g. iOS)', () async {
      repository.checkResult = const Ok(SmsPermissionStatus.unsupported);
      final useCase = CheckSmsPermissionUseCase(repository);

      final result = await useCase();

      expect(
        (result as Ok<SmsPermissionStatus>).value,
        SmsPermissionStatus.unsupported,
      );
      expect(repository.requestCalls, 0);
    });
  });

  group('RequestSmsPermissionUseCase', () {
    test('propagates permanentlyDenied so the UI can offer settings', () async {
      repository.requestResult = const Ok(
        SmsPermissionStatus.permanentlyDenied,
      );
      final useCase = RequestSmsPermissionUseCase(repository);

      final result = await useCase();

      expect(
        (result as Ok<SmsPermissionStatus>).value,
        SmsPermissionStatus.permanentlyDenied,
      );
    });

    test('propagates a repository failure', () async {
      repository.requestResult = const Err(UnknownFailure());
      final useCase = RequestSmsPermissionUseCase(repository);

      final result = await useCase();

      expect(result, isA<Err<SmsPermissionStatus>>());
    });
  });
}
