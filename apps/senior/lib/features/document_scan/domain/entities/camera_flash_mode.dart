/// Flash control shown in the camera screen — OFF/ON/자동, per
/// feature-spec.md ADD/NEW-3. Always shown with a visible text label, never
/// an icon-only toggle (ui-principles.md/ui-spec.md "카메라 플래시 상태").
enum CameraFlashMode {
  off,
  on,
  auto;

  String get label => switch (this) {
    CameraFlashMode.off => '플래시 꺼짐',
    CameraFlashMode.on => '플래시 켜짐',
    CameraFlashMode.auto => '플래시 자동',
  };

  CameraFlashMode get next => switch (this) {
    CameraFlashMode.off => CameraFlashMode.on,
    CameraFlashMode.on => CameraFlashMode.auto,
    CameraFlashMode.auto => CameraFlashMode.off,
  };
}
