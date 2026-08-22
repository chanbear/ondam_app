import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/features/profile/domain/entities/profile.dart';
import 'package:ondam_senior/features/profile/domain/repositories/profile_repository.dart';

class FakeProfileRepository implements ProfileRepository {
  Result<Profile?> getMyProfileResult = const Ok(null);
  Result<void> saveProfileResult = const Ok(null);

  Profile? savedProfile;
  int saveCalls = 0;
  int getMyProfileCalls = 0;

  @override
  Future<Result<Profile?>> getMyProfile() async {
    getMyProfileCalls++;
    return getMyProfileResult;
  }

  @override
  Future<Result<void>> saveProfile(Profile profile) async {
    saveCalls++;
    savedProfile = profile;
    return saveProfileResult;
  }
}
