import 'package:ondam_core/ondam_core.dart';

import '../repositories/connection_repository.dart';

class RevokeGuardianLinkUseCase {
  const RevokeGuardianLinkUseCase(this._repository);

  final ConnectionRepository _repository;

  Future<Result<void>> call(String linkId) => _repository.revokeLink(linkId);
}
