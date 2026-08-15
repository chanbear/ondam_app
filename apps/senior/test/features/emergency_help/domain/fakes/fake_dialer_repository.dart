import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/features/emergency_help/domain/repositories/dialer_repository.dart';

class FakeDialerRepository implements DialerRepository {
  Result<void> result = const Ok(null);
  String? lastCalledNumber;

  @override
  Future<Result<void>> call(String phoneNumber) async {
    lastCalledNumber = phoneNumber;
    return result;
  }
}
