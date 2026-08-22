import 'package:ondam_core/ondam_core.dart';

/// Looks up the phone number of the calling elder's connected guardian, so
/// GetGuardianPhoneUseCase can hand it to DialerRepository. A `null` value
/// inside [Ok] means the elder simply has no accepted guardian connection
/// yet — that's an expected state, not a [Failure].
abstract class GuardianContactRepository {
  Future<Result<String?>> getGuardianPhone();
}
