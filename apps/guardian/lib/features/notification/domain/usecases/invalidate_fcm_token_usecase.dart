import 'package:ondam_core/ondam_core.dart';

import '../repositories/fcm_token_repository.dart';

class InvalidateFcmTokenUseCase {
  const InvalidateFcmTokenUseCase(this._repository);

  final FcmTokenRepository _repository;

  Future<Result<void>> call(String token) => _repository.invalidateToken(token);
}
