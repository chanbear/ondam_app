import 'package:ondam_core/ondam_core.dart';

import '../entities/camera_permission_status.dart';

/// Camera PERMISSION concern only — deliberately does not expose camera
/// hardware control (preview stream, flash, shutter). Those are UI-bound,
/// stateful, platform-controller resources (comparable to a
/// `TextEditingController`/`AnimationController`), so they live in the
/// presentation layer's `CameraPreviewView` widget (flutter.md: "로컬 UI
/// 상태... 애니메이션 컨트롤러 등에만 StatefulWidget 사용"), not behind a
/// Result-returning Repository call. This repository covers the one part
/// of "camera" that genuinely is a business/domain concern: whether this
/// app is allowed to use the camera at all.
abstract class CameraRepository {
  Future<Result<CameraPermissionStatus>> checkPermission();

  Future<Result<CameraPermissionStatus>> requestPermission();
}
