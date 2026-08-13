/// Domain-level camera permission state — deliberately not the
/// `permission_handler` package's own enum, so domain stays package-free.
/// The data layer maps `permission_handler`'s `PermissionStatus` onto this.
enum CameraPermissionStatus {
  granted,

  /// Denied, but asking again is still possible (OS will show the prompt).
  denied,

  /// Denied permanently — the OS will not show the prompt again; the user
  /// must open system settings. UI must offer a distinct "설정 열기" path,
  /// not just a plain "재요청" retry.
  permanentlyDenied,

  /// iOS-only: blocked by a system restriction (e.g. parental controls),
  /// not something a retry or a settings toggle can fix.
  restricted,
}
