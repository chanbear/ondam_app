/// A photo captured by the device camera, not yet submitted for analysis.
/// Pure value type — no Flutter/camera package dependency (domain layer
/// rule). [localPath] points at a temporary file on device storage; per
/// technical-decisions.md §1-8 ("원본 즉시 삭제"), this file only exists
/// locally until analysis completes (or the user cancels), and is never
/// uploaded anywhere persistent by this Phase (no analysis backend yet).
class CapturedPhoto {
  const CapturedPhoto({required this.localPath, required this.capturedAt});

  final String localPath;
  final DateTime capturedAt;
}
