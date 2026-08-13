import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';

import '../repositories/auth_repository.dart';

/// Roles currently held by the signed-in user — used for the non-blocking
/// role-guidance prompt (e.g. "이 번호는 이미 보호자로도 등록되어 있어요").
class GetRolesUseCase {
  const GetRolesUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<List<UserRole>>> call() => _repository.getRoles();
}
