import 'package:ondam_core/ondam_core.dart';

import '../repositories/guardian_contact_repository.dart';

class GetGuardianPhoneUseCase {
  const GetGuardianPhoneUseCase(this._repository);

  final GuardianContactRepository _repository;

  Future<Result<String?>> call() => _repository.getGuardianPhone();
}
