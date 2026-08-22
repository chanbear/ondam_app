/// Domain-level location permission state — mirrors
/// `document_scan`'s `CameraPermissionStatus` shape so the same
/// allow/denied/permanentlyDenied UI pattern applies (see
/// `document_scan_camera_page.dart`). Kept independent of `geolocator`'s own
/// `LocationPermission` enum so domain stays package-free; the data layer
/// maps onto this. No `restricted` case — unlike `permission_handler`,
/// `geolocator`'s own permission API never distinguishes an iOS parental-
/// control restriction from a plain denial.
enum LocationPermissionStatus {
  granted,

  /// Denied, but asking again is still possible (OS will show the prompt).
  denied,

  /// Denied permanently — the OS will not show the prompt again; the user
  /// must open system settings.
  permanentlyDenied,

  /// The device's location service (GPS/Wi-Fi positioning) itself is turned
  /// off at the OS level — distinct from app permission, since even a
  /// granted app permission can't produce a position while this is off.
  serviceDisabled,
}
