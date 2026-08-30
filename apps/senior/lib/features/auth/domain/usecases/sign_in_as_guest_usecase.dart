import 'package:ondam_core/ondam_core.dart';

import '../repositories/auth_repository.dart';

/// Starts an anonymous Supabase session (회원가입 없이 사용하기). No input to
/// validate — just delegates.
class SignInAsGuestUseCase {
  const SignInAsGuestUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call() {
    return _repository.signInAsGuest();
  }
}
