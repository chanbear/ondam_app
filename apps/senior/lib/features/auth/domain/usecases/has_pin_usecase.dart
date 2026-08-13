import 'package:ondam_core/ondam_core.dart';

import '../repositories/auth_repository.dart';

/// Router-support check: does the signed-in user already have a PIN set.
/// Decides PIN-setup vs PIN-entry after a session exists.
class HasPinUseCase {
  const HasPinUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<bool>> call() => _repository.hasPin();
}
