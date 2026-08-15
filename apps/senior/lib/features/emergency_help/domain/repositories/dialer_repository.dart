import 'package:ondam_core/ondam_core.dart';

/// Launches the device's phone dialer. Deliberately not modeled as a
/// stateful platform controller (unlike `CameraPreviewView`) — a phone call
/// launch is a single fire-and-forget action with a clear success/failure
/// outcome, so it fits the same Repository/Result shape as other
/// business-level device capability checks (see `CameraRepository`).
abstract class DialerRepository {
  Future<Result<void>> call(String phoneNumber);
}
