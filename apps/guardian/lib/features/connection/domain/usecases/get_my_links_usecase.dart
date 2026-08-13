import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';

import '../repositories/connection_repository.dart';

class GetMyLinksUseCase {
  const GetMyLinksUseCase(this._repository);

  final ConnectionRepository _repository;

  Future<Result<List<GuardianLink>>> call() => _repository.getMyLinks();
}
