import 'package:ondam_core/ondam_core.dart';

import '../entities/profile.dart';

/// The elder's saved [Profile] (name/age) — same shape as
/// `core/location`'s `RegionRepository`.
abstract class ProfileRepository {
  Future<Result<Profile?>> getMyProfile();

  Future<Result<void>> saveProfile(Profile profile);
}
