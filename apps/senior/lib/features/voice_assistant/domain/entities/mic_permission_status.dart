/// Domain-level microphone permission state — deliberately not the
/// `permission_handler` package's own enum, so domain stays package-free.
/// The data layer maps `permission_handler`'s `PermissionStatus` onto this.
/// Mirrors `document_scan`'s `CameraPermissionStatus` shape.
enum MicPermissionStatus {
  granted,

  /// Denied, but asking again is still possible (OS will show the prompt).
  denied,

  /// Denied permanently — the OS will not show the prompt again; the user
  /// must open system settings.
  permanentlyDenied,

  /// iOS-only: blocked by a system restriction, not something a retry or a
  /// settings toggle can fix.
  restricted,
}
