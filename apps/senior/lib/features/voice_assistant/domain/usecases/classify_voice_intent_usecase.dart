import '../entities/voice_intent.dart';

/// Maps recognized speech text to a [VoiceIntent] via plain keyword
/// matching — no network call, no AI (technical-decisions.md §5-2 OPEN
/// QUESTIONS 10 DECIDED). Pure Dart, no Flutter dependency, so it stays
/// unit-testable without a widget harness or a fake STT engine.
class ClassifyVoiceIntentUseCase {
  const ClassifyVoiceIntentUseCase();

  static const _documentScanKeywords = ['문서', '서류', '촬영', '찍어'];
  static const _messageCheckKeywords = ['문자', '메시지', '메세지'];
  static const _emergencyHelpKeywords = ['긴급', '도와줘', '도움', '살려'];
  static const _welfareCenterKeywords = ['경로당'];

  VoiceIntent call(String recognizedText) {
    final text = recognizedText.trim();
    if (text.isEmpty) return VoiceIntent.unrecognized;

    if (_documentScanKeywords.any(text.contains)) {
      return VoiceIntent.documentScan;
    }
    if (_messageCheckKeywords.any(text.contains)) {
      return VoiceIntent.messageCheck;
    }
    if (_emergencyHelpKeywords.any(text.contains)) {
      return VoiceIntent.emergencyHelp;
    }
    if (_welfareCenterKeywords.any(text.contains)) {
      return VoiceIntent.welfareCenter;
    }
    return VoiceIntent.unrecognized;
  }
}
