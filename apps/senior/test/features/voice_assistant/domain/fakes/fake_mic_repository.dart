import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/features/voice_assistant/domain/entities/mic_permission_status.dart';
import 'package:ondam_senior/features/voice_assistant/domain/repositories/mic_repository.dart';

class FakeMicRepository implements MicRepository {
  Result<MicPermissionStatus> checkResult = const Ok(
    MicPermissionStatus.denied,
  );
  Result<MicPermissionStatus> requestResult = const Ok(
    MicPermissionStatus.granted,
  );

  int checkCalls = 0;
  int requestCalls = 0;

  @override
  Future<Result<MicPermissionStatus>> checkPermission() async {
    checkCalls++;
    return checkResult;
  }

  @override
  Future<Result<MicPermissionStatus>> requestPermission() async {
    requestCalls++;
    return requestResult;
  }
}
