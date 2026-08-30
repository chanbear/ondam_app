import 'package:ondam_core/ondam_core.dart';

import '../entities/social_auth_provider.dart';
import '../repositories/auth_repository.dart';

/// Launches the OAuth browser flow for [SocialAuthProvider]. No input to
/// validate here (unlike [SignUpUseCase]'s phone/name) — just delegates.
class SignInWithOAuthUseCase {
  const SignInWithOAuthUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call(SocialAuthProvider provider) {
    return _repository.signInWithOAuth(provider);
  }
}
