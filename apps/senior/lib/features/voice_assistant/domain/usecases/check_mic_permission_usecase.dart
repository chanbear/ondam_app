import 'package:ondam_core/ondam_core.dart';

import '../entities/mic_permission_status.dart';
import '../repositories/mic_repository.dart';

/// Reads the current mic permission WITHOUT prompting the OS dialog — used
/// when the voice assistant screen is entered, to decide which state to show
/// before ever asking the user for anything.
class CheckMicPermissionUseCase {
  const CheckMicPermissionUseCase(this._repository);

  final MicRepository _repository;

  Future<Result<MicPermissionStatus>> call() => _repository.checkPermission();
}
