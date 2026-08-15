import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/features/voice_assistant/domain/entities/mic_permission_status.dart';
import 'package:ondam_senior/features/voice_assistant/domain/usecases/check_mic_permission_usecase.dart';
import 'package:ondam_senior/features/voice_assistant/domain/usecases/request_mic_permission_usecase.dart';

import '../fakes/fake_mic_repository.dart';

void main() {
  late FakeMicRepository repository;

  setUp(() {
    repository = FakeMicRepository();
  });

  group('CheckMicPermissionUseCase', () {
    test('returns granted when the repository reports granted', () async {
      repository.checkResult = const Ok(MicPermissionStatus.granted);
      final useCase = CheckMicPermissionUseCase(repository);

      final result = await useCase();

      expect(
        (result as Ok<MicPermissionStatus>).value,
        MicPermissionStatus.granted,
      );
      expect(repository.checkCalls, 1);
    });

    test('returns denied without prompting the OS', () async {
      repository.checkResult = const Ok(MicPermissionStatus.denied);
      final useCase = CheckMicPermissionUseCase(repository);

      final result = await useCase();

      expect(
        (result as Ok<MicPermissionStatus>).value,
        MicPermissionStatus.denied,
      );
      expect(repository.requestCalls, 0);
    });
  });

  group('RequestMicPermissionUseCase', () {
    test('propagates permanentlyDenied so the UI can offer settings', () async {
      repository.requestResult = const Ok(
        MicPermissionStatus.permanentlyDenied,
      );
      final useCase = RequestMicPermissionUseCase(repository);

      final result = await useCase();

      expect(
        (result as Ok<MicPermissionStatus>).value,
        MicPermissionStatus.permanentlyDenied,
      );
    });

    test('propagates a repository failure', () async {
      repository.requestResult = const Err(UnknownFailure());
      final useCase = RequestMicPermissionUseCase(repository);

      final result = await useCase();

      expect(result, isA<Err<MicPermissionStatus>>());
    });
  });
}
