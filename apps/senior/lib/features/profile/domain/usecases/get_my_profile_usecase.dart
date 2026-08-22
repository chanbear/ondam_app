import 'package:ondam_core/ondam_core.dart';

import '../entities/profile.dart';
import '../repositories/profile_repository.dart';

class GetMyProfileUseCase {
  const GetMyProfileUseCase(this._repository);

  final ProfileRepository _repository;

  Future<Result<Profile?>> call() => _repository.getMyProfile();
}
