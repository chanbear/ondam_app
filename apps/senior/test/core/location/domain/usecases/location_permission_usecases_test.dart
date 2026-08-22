import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/core/location/domain/entities/location_permission_status.dart';
import 'package:ondam_senior/core/location/domain/usecases/check_location_permission_usecase.dart';
import 'package:ondam_senior/core/location/domain/usecases/request_location_permission_usecase.dart';

import '../fakes/fake_location_repository.dart';

void main() {
  late FakeLocationRepository repository;

  setUp(() {
    repository = FakeLocationRepository();
  });

  group('CheckLocationPermissionUseCase', () {
    test('returns granted when the repository reports granted', () async {
      repository.checkResult = const Ok(LocationPermissionStatus.granted);
      final useCase = CheckLocationPermissionUseCase(repository);

      final result = await useCase();

      expect(
        (result as Ok<LocationPermissionStatus>).value,
        LocationPermissionStatus.granted,
      );
      expect(repository.checkCalls, 1);
      expect(repository.requestCalls, 0);
    });

    test('returns serviceDisabled without prompting the OS', () async {
      repository.checkResult = const Ok(
        LocationPermissionStatus.serviceDisabled,
      );
      final useCase = CheckLocationPermissionUseCase(repository);

      final result = await useCase();

      expect(
        (result as Ok<LocationPermissionStatus>).value,
        LocationPermissionStatus.serviceDisabled,
      );
    });
  });

  group('RequestLocationPermissionUseCase', () {
    test('propagates permanentlyDenied so the UI can offer settings', () async {
      repository.requestResult = const Ok(
        LocationPermissionStatus.permanentlyDenied,
      );
      final useCase = RequestLocationPermissionUseCase(repository);

      final result = await useCase();

      expect(
        (result as Ok<LocationPermissionStatus>).value,
        LocationPermissionStatus.permanentlyDenied,
      );
    });

    test('propagates a plain denial', () async {
      repository.requestResult = const Ok(LocationPermissionStatus.denied);
      final useCase = RequestLocationPermissionUseCase(repository);

      final result = await useCase();

      expect(
        (result as Ok<LocationPermissionStatus>).value,
        LocationPermissionStatus.denied,
      );
    });

    test('propagates a repository failure', () async {
      repository.requestResult = const Err(UnknownFailure());
      final useCase = RequestLocationPermissionUseCase(repository);

      final result = await useCase();

      expect(result, isA<Err<LocationPermissionStatus>>());
    });
  });
}
