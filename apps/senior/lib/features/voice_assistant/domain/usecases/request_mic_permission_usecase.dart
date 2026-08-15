import 'package:ondam_core/ondam_core.dart';

import '../entities/mic_permission_status.dart';
import '../repositories/mic_repository.dart';

/// Triggers the actual OS permission prompt.
class RequestMicPermissionUseCase {
  const RequestMicPermissionUseCase(this._repository);

  final MicRepository _repository;

  Future<Result<MicPermissionStatus>> call() => _repository.requestPermission();
}
