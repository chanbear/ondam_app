import 'package:ondam_core/ondam_core.dart';

import '../repositories/fcm_token_repository.dart';

class RegisterFcmTokenUseCase {
  const RegisterFcmTokenUseCase(this._repository);

  final FcmTokenRepository _repository;

  Future<Result<void>> call({
    required String token,
    required Map<String, dynamic> deviceInfo,
  }) => _repository.registerToken(token: token, deviceInfo: deviceInfo);
}
