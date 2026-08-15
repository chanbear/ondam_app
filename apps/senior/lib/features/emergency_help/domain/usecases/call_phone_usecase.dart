import 'package:ondam_core/ondam_core.dart';

import '../repositories/dialer_repository.dart';

class CallPhoneUseCase {
  const CallPhoneUseCase(this._repository);

  final DialerRepository _repository;

  Future<Result<void>> call(String phoneNumber) {
    if (phoneNumber.trim().isEmpty) {
      return Future.value(const Err(ValidationFailure('전화번호가 없어요.')));
    }
    return _repository.call(phoneNumber);
  }
}
