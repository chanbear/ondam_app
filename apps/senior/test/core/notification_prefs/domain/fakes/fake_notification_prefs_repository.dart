import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/core/notification_prefs/domain/repositories/notification_prefs_repository.dart';

class FakeNotificationPrefsRepository implements NotificationPrefsRepository {
  Result<bool> getGuardianNotifyEnabledResult = const Ok(true);
  Result<void> setGuardianNotifyEnabledResult = const Ok(null);

  bool? savedValue;
  int getCalls = 0;
  int setCalls = 0;

  @override
  Future<Result<bool>> getGuardianNotifyEnabled() async {
    getCalls++;
    return getGuardianNotifyEnabledResult;
  }

  @override
  Future<Result<void>> setGuardianNotifyEnabled(bool enabled) async {
    setCalls++;
    savedValue = enabled;
    return setGuardianNotifyEnabledResult;
  }
}
