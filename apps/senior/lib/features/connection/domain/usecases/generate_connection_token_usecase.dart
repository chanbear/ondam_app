import 'package:ondam_core/ondam_core.dart';

import '../entities/connection_token.dart';
import '../repositories/connection_repository.dart';

class GenerateConnectionTokenUseCase {
  const GenerateConnectionTokenUseCase(this._repository);

  final ConnectionRepository _repository;

  Future<Result<ConnectionToken>> call() =>
      _repository.generateConnectionToken();
}
