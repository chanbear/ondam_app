import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';

import '../repositories/connection_repository.dart';

class RedeemConnectionTokenUseCase {
  const RedeemConnectionTokenUseCase(this._repository);

  final ConnectionRepository _repository;

  Future<Result<GuardianLink>> call(String token) {
    if (token.isEmpty) {
      return Future.value(const Err(ValidationFailure('잘못된 QR 코드예요.')));
    }
    return _repository.redeemConnectionToken(token);
  }
}
