/// A photo captured by the device camera, not yet submitted for analysis.
/// Pure value type — no Flutter/camera package dependency (domain layer
/// rule). [localPath] points at a temporary file on device storage.
/// `AnalysisRepositoryImpl` uploads this file to the `document-photos`
/// Storage bucket for analysis; the server-side copy is deleted immediately
/// after the Edge Function processes it, regardless of outcome
/// (technical-decisions.md §1-8 "원본 즉시 삭제"). The local copy itself is
/// not yet actively deleted by this feature — a known, smaller follow-up,
/// not a violation of §1-8 (which is about the analysis pipeline's own
/// copy), since this device-local temp file was never "uploaded anywhere
/// persistent" to begin with.
class CapturedPhoto {
  const CapturedPhoto({required this.localPath, required this.capturedAt});

  final String localPath;
  final DateTime capturedAt;
}
