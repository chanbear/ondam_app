import 'package:ondam_core/ondam_core.dart';

import '../entities/mic_permission_status.dart';

/// Microphone PERMISSION concern only — mirrors `document_scan`'s
/// `CameraRepository` split (permission is a domain concern; the live
/// STT/TTS engines themselves are UI-bound, stateful, platform-controller
/// resources that live in the presentation layer's `VoiceAssistantPage`,
/// same reasoning as `CameraPreviewView` owning `CameraController`).
abstract class MicRepository {
  Future<Result<MicPermissionStatus>> checkPermission();

  Future<Result<MicPermissionStatus>> requestPermission();
}
