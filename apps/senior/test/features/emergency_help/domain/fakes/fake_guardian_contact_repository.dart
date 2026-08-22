import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/features/emergency_help/domain/repositories/guardian_contact_repository.dart';

class FakeGuardianContactRepository implements GuardianContactRepository {
  Result<String?> result = const Ok(null);

  @override
  Future<Result<String?>> getGuardianPhone() async => result;
}
