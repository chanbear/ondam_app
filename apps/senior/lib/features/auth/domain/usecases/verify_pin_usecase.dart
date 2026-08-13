import 'package:ondam_core/ondam_core.dart';

import '../entities/pin_verify_result.dart';
import '../repositories/auth_repository.dart';

/// Everyday app-reentry PIN check (Session ≠ PIN Gate — technical-decisions.md
/// §1-3-A). Lockout state is entirely server-authoritative; this use case
/// never computes or predicts lockout locally.
class VerifyPinUseCase {
  const VerifyPinUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<PinVerifyResult>> call(String pin) {
    if (!RegExp(r'^[0-9]{4}$').hasMatch(pin)) {
      return Future.value(const Err(ValidationFailure('PIN은 4자리 숫자로 입력해주세요.')));
    }
    return _repository.verifyPin(pin);
  }
}
