/// Domain-level SMS inbox access state — mirrors
/// `document_scan`'s `CameraPermissionStatus` shape/naming for consistency,
/// with one addition: [unsupported] for platforms that have no SMS-inbox
/// permission concept at all (iOS, or any non-Android platform). This is
/// deliberately not a plain "denied" — the UI must offer a completely
/// different flow (manual paste/입력), not a permission-request retry.
enum SmsPermissionStatus {
  granted,

  /// Denied, but asking again is still possible (OS will show the prompt).
  denied,

  /// Denied permanently — the OS will not show the prompt again; the user
  /// must open system settings.
  permanentlyDenied,

  /// This platform has no automatic SMS-inbox access at all (iOS today).
  /// Never resolved by requesting permission — only the manual-input flow
  /// applies.
  unsupported,
}
