import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/features/document_scan/domain/entities/camera_permission_status.dart';
import 'package:ondam_senior/features/document_scan/domain/repositories/camera_repository.dart';

class FakeCameraRepository implements CameraRepository {
  Result<CameraPermissionStatus> checkResult = const Ok(
    CameraPermissionStatus.denied,
  );
  Result<CameraPermissionStatus> requestResult = const Ok(
    CameraPermissionStatus.granted,
  );

  int checkCalls = 0;
  int requestCalls = 0;

  @override
  Future<Result<CameraPermissionStatus>> checkPermission() async {
    checkCalls++;
    return checkResult;
  }

  @override
  Future<Result<CameraPermissionStatus>> requestPermission() async {
    requestCalls++;
    return requestResult;
  }
}
