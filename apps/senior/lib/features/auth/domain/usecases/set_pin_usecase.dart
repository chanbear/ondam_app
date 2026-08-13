import 'package:ondam_core/ondam_core.dart';

import '../repositories/auth_repository.dart';

/// First-time PIN setup, right after signup.
class SetPinUseCase {
  const SetPinUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call(String pin) {
    if (!RegExp(r'^[0-9]{4}$').hasMatch(pin)) {
      return Future.value(const Err(ValidationFailure('PIN은 4자리 숫자로 입력해주세요.')));
    }
    return _repository.setPin(pin);
  }
}
