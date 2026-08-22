import 'package:ondam_core/ondam_core.dart';

import '../entities/profile.dart';
import '../repositories/profile_repository.dart';

class SaveProfileUseCase {
  const SaveProfileUseCase(this._repository);

  final ProfileRepository _repository;

  Future<Result<void>> call({required String name, required String age}) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return Future.value(const Err(ValidationFailure('이름을 입력해주세요.')));
    }

    final parsedAge = int.tryParse(age.trim());
    if (parsedAge == null || parsedAge < 1 || parsedAge > 119) {
      return Future.value(const Err(ValidationFailure('나이를 올바르게 입력해주세요.')));
    }

    return _repository.saveProfile(Profile(name: trimmedName, age: parsedAge));
  }
}
