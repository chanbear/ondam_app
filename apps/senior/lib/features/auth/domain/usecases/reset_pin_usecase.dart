import 'package:ondam_core/ondam_core.dart';

import '../repositories/auth_repository.dart';

/// PIN-forgot flow, step 2: after the client has re-authenticated via a
/// fresh OTP verification (VerifyOtpUseCase), overwrite the PIN with a new
/// one. The server independently checks session freshness — this use case
/// does not decide that, it only validates format before calling out.
class ResetPinUseCase {
  const ResetPinUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call(String newPin) {
    if (!RegExp(r'^[0-9]{4}$').hasMatch(newPin)) {
      return Future.value(const Err(ValidationFailure('PIN은 4자리 숫자로 입력해주세요.')));
    }
    return _repository.resetPin(newPin);
  }
}
