import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';

import '../repositories/auth_repository.dart';

/// Onboarding role choice ("저는 어르신입니다" / "저는 보호자입니다"). A
/// user may hold both roles at once (technical-decisions.md OPEN QUESTIONS
/// 15 — DECIDED, B안), so this is additive, not a replace.
class AddRoleUseCase {
  const AddRoleUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call(UserRole role) => _repository.addRole(role);
}
