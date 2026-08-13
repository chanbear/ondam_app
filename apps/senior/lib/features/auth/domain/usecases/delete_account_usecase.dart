import 'package:ondam_core/ondam_core.dart';

import '../repositories/auth_repository.dart';

/// Permanently deletes the current user's account and cascades all owned
/// data (technical-decisions.md §2 item 10). Irreversible.
class DeleteAccountUseCase {
  const DeleteAccountUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call() => _repository.deleteAccount();
}
