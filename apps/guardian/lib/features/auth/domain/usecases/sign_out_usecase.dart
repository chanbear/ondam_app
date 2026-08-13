import 'package:ondam_core/ondam_core.dart';

import '../repositories/auth_repository.dart';

/// Full sign-out — ends the Supabase Auth session. Presentation is
/// responsible for also clearing the memory-only PIN gate (`pinVerifiedProvider`)
/// after this succeeds; that is not a repository/session concern.
class SignOutUseCase {
  const SignOutUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call() => _repository.signOut();
}
