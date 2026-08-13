import 'package:ondam_core/ondam_core.dart';

import '../repositories/auth_repository.dart';

/// Verifies the 6-digit OTP code, establishing the Supabase Auth session.
class VerifyOtpUseCase {
  const VerifyOtpUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call({
    required String phoneNumber,
    required String otp,
  }) {
    if (!RegExp(r'^[0-9]{6}$').hasMatch(otp)) {
      return Future.value(const Err(ValidationFailure('6자리 인증번호를 입력해주세요.')));
    }
    return _repository.verifyOtp(phoneNumber: phoneNumber, otp: otp);
  }
}
