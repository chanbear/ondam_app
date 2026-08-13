import 'package:ondam_core/ondam_core.dart';

import '../repositories/connection_repository.dart';

class RespondToConnectionRequestUseCase {
  const RespondToConnectionRequestUseCase(this._repository);

  final ConnectionRepository _repository;

  Future<Result<void>> call({required String linkId, required bool accept}) {
    return _repository.respondToRequest(linkId: linkId, accept: accept);
  }
}
