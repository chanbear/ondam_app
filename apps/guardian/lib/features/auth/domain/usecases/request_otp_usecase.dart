import 'package:ondam_core/ondam_core.dart';

import '../repositories/auth_repository.dart';
import '../utils/phone_number_formatter.dart';

/// Sends the first OTP SMS for signup/login/new-device/PIN-forgot re-auth.
class RequestOtpUseCase {
  const RequestOtpUseCase(this._repository);

  final AuthRepository _repository;

  /// [rawPhoneNumber] is whatever the user typed (digits, may include
  /// dashes/spaces) — normalized to E.164 before hitting the network.
  Future<Result<String>> call(String rawPhoneNumber) async {
    final normalized = toE164KoreanPhoneNumber(rawPhoneNumber);
    if (normalized == null) {
      return const Err(ValidationFailure('올바른 휴대폰 번호를 입력해주세요.'));
    }

    final result = await _repository.requestOtp(normalized);
    return switch (result) {
      Ok() => Ok(normalized),
      Err(:final failure) => Err(failure),
    };
  }
}
