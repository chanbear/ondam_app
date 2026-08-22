import 'package:ondam_core/ondam_core.dart';

import '../repositories/auth_repository.dart';
import '../utils/phone_number_formatter.dart';

/// Normalizes name/phone input and delegates to the repository — no OTP
/// (technical-decisions.md §1-3-A "OTP 제거"). Format validation lives here,
/// not in the repository or presentation layer.
class SignUpUseCase {
  const SignUpUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call({
    required String name,
    required String rawPhoneNumber,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return const Err(ValidationFailure('이름을 입력해주세요.'));
    }
    final phoneNumber = toE164KoreanPhoneNumber(rawPhoneNumber);
    if (phoneNumber == null) {
      return const Err(ValidationFailure('휴대폰 번호를 다시 확인해주세요.'));
    }
    return _repository.signUp(name: trimmedName, phoneNumber: phoneNumber);
  }
}
