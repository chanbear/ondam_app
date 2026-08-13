import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/features/document_scan/domain/entities/camera_permission_status.dart';
import 'package:ondam_senior/features/document_scan/domain/usecases/check_camera_permission_usecase.dart';
import 'package:ondam_senior/features/document_scan/domain/usecases/request_camera_permission_usecase.dart';

import '../fakes/fake_camera_repository.dart';

void main() {
  late FakeCameraRepository repository;

  setUp(() {
    repository = FakeCameraRepository();
  });

  group('CheckCameraPermissionUseCase', () {
    test('returns granted when the repository reports granted', () async {
      repository.checkResult = const Ok(CameraPermissionStatus.granted);
      final useCase = CheckCameraPermissionUseCase(repository);

      final result = await useCase();

      expect(result, isA<Ok<CameraPermissionStatus>>());
      expect(
        (result as Ok<CameraPermissionStatus>).value,
        CameraPermissionStatus.granted,
      );
      expect(repository.checkCalls, 1);
    });

    test('returns denied without prompting the OS', () async {
      repository.checkResult = const Ok(CameraPermissionStatus.denied);
      final useCase = CheckCameraPermissionUseCase(repository);

      final result = await useCase();

      expect(
        (result as Ok<CameraPermissionStatus>).value,
        CameraPermissionStatus.denied,
      );
      expect(repository.requestCalls, 0);
    });
  });

  group('RequestCameraPermissionUseCase', () {
    test('propagates permanentlyDenied so the UI can offer settings', () async {
      repository.requestResult = const Ok(
        CameraPermissionStatus.permanentlyDenied,
      );
      final useCase = RequestCameraPermissionUseCase(repository);

      final result = await useCase();

      expect(
        (result as Ok<CameraPermissionStatus>).value,
        CameraPermissionStatus.permanentlyDenied,
      );
    });

    test('propagates a repository failure', () async {
      repository.requestResult = const Err(UnknownFailure());
      final useCase = RequestCameraPermissionUseCase(repository);

      final result = await useCase();

      expect(result, isA<Err<CameraPermissionStatus>>());
    });
  });
}
