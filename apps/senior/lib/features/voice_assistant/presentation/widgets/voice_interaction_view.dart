import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:ondam_design_system/ondam_design_system.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../../core/locale/locale_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/voice_intent.dart';
import '../providers/voice_assistant_di_providers.dart';

enum _Stage { idle, listening, processing, answered }

/// STT/TTS 엔진에 넘길 locale 태그 — 다국어 지원(ONDAM i18n)에서 앱 locale과
/// 연결하는 지점. 단, [ClassifyVoiceIntentUseCase]는 한국어 키워드 매칭만
/// 지원하므로(재설계 범위 밖) 다른 언어를 선택해도 인식된 문장의 의도 파악은
/// 여전히 한국어 기준이다 — 이 화면의 안내 문구(예시 명령어)에 한국어
/// 원문을 그대로 남겨둔 이유이기도 하다(l10n 키 `voiceUnrecognizedAnswer`).
String _ttsLocaleTag(Locale locale) => switch (locale.languageCode) {
  'en' => 'en-US',
  'zh' => 'zh-CN',
  'ja' => 'ja-JP',
  _ => 'ko-KR',
};

String _sttLocaleId(Locale locale) => switch (locale.languageCode) {
  'en' => 'en_US',
  'zh' => 'zh_CN',
  'ja' => 'ja_JP',
  _ => 'ko_KR',
};

/// Owns the live `SpeechToText`/`FlutterTts` engines directly — same
/// reasoning as `document_scan`'s `CameraPreviewView` owning
/// `CameraController`: a hardware/UI-bound, disposable controller belongs in
/// local `StatefulWidget` state (flutter.md), not behind a Result-returning
/// Repository. Mic PERMISSION is the one Repository-worthy concern here
/// (see `MicRepository`) and is already granted by the time this widget is
/// built (gated by `VoiceAssistantPage`).
class VoiceInteractionView extends ConsumerStatefulWidget {
  const VoiceInteractionView({
    super.key,
    required this.easyMode,
    required this.onNavigate,
  });

  final bool easyMode;

  /// 목적지가 분명한 Intent가 인식되면 곧장 호출된다(요구사항: "이동하기"
  /// 확인 생략). 실제 화면 전환은 이 위젯이 알지 못하는 상위(호출부)의
  /// 책임이다 — 여기서는 "언제" 호출할지만 안다.
  final ValueChanged<VoiceIntent> onNavigate;

  @override
  ConsumerState<VoiceInteractionView> createState() =>
      _VoiceInteractionViewState();
}

class _VoiceInteractionViewState extends ConsumerState<VoiceInteractionView> {
  final _speech = SpeechToText();
  final _tts = FlutterTts();

  bool _engineReady = false;
  String? _initError;
  _Stage _stage = _Stage.idle;
  String _recognizedText = '';
  String _answerText = '';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final available = await _speech.initialize(
        onError: _onSttError,
        onStatus: _onSttStatus,
      );
      await _tts.setLanguage(_ttsLocaleTag(ref.read(localeControllerProvider)));
      await _tts.awaitSpeakCompletion(true);
      if (!mounted) return;
      setState(() {
        _engineReady = available;
        _initError = available
            ? null
            : AppLocalizations.of(context)!.voiceUnavailableError;
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _initError = AppLocalizations.of(context)!.voiceInitError,
        );
      }
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  Future<void> _startListening() async {
    // 이전 안내(특히 인식 실패 안내)가 아직 재생 중일 수 있다 — 새로 듣기
    // 시작하기 전에 반드시 멈춘다. stop()이 실패해도(이미 멈춰있는 등)
    // 듣기 시작을 막아서는 안 되므로 결과와 무관하게 항상 진행한다.
    await _stopSpeaking();
    if (!mounted) return;
    setState(() {
      _stage = _Stage.listening;
      _recognizedText = '';
    });
    try {
      await _speech.listen(
        onResult: _onResult,
        listenOptions: SpeechListenOptions(
          localeId: _sttLocaleId(ref.read(localeControllerProvider)),
        ),
      );
    } catch (_) {
      _respond('');
    }
  }

  Future<void> _stopSpeaking() async {
    try {
      await _tts.stop();
    } catch (_) {
      // 멈추는 것 자체가 실패해도(예: 이미 재생 중이 아님) 듣기 시작을
      // 막지 않는다 — 사용자에게는 "다시 말씀해주세요"가 항상 동작해야 한다.
    }
  }

  void _onResult(SpeechRecognitionResult result) {
    if (!result.finalResult) {
      setState(() => _recognizedText = result.recognizedWords);
      return;
    }
    _respond(result.recognizedWords);
  }

  void _onSttStatus(String status) {
    // Listening ended (silence/timeout) without a final result ever
    // arriving via [_onResult] — treat the same as an unrecognized
    // utterance, never as a hard error (ui-spec.md "인식 실패/무음").
    if (status == 'done' && _stage == _Stage.listening) {
      _respond('');
    }
  }

  void _onSttError(SpeechRecognitionError error) {
    if (_stage != _Stage.listening) return;
    _respond('');
  }

  void _respond(String recognizedText) {
    if (!mounted) return;
    setState(() {
      _recognizedText = recognizedText;
      _stage = _Stage.processing;
    });
    final intent = ref
        .read(classifyVoiceIntentUseCaseProvider)
        .call(recognizedText);

    // 목적지가 분명한 명령은 확인 화면("이동하기")을 거치지 않고 곧장
    // 이동한다 — ambiguous/unknown(unrecognized)만 아래로 내려가 기존
    // 안내/재시도 흐름을 유지한다.
    if (intent.hasImmediateDestination) {
      widget.onNavigate(intent);
      return;
    }

    final answer = AppLocalizations.of(context)!.voiceUnrecognizedAnswer;
    setState(() {
      _answerText = answer;
      _stage = _Stage.answered;
    });
    _speak(answer);
  }

  Future<void> _speak(String text) async {
    try {
      await _tts.speak(text);
    } catch (_) {
      // TTS 재생 실패는 조용히 무시한다 — 답변 텍스트는 이미 화면에 표시되어
      // 있어(ui-spec.md "음성만으로 끝내지 않음") 음성 없이도 내용 전달은 된다.
    }
  }

  @override
  Widget build(BuildContext context) {
    final initError = _initError;
    if (initError != null) {
      return AppError(
        message: initError,
        onRetry: () {
          setState(() => _initError = null);
          _initialize();
        },
      );
    }
    if (!_engineReady) {
      return AppLoading(message: AppLocalizations.of(context)!.voicePreparing);
    }

    return switch (_stage) {
      _Stage.idle => _IdleView(
        easyMode: widget.easyMode,
        onStart: _startListening,
      ),
      _Stage.listening => _ListeningView(
        easyMode: widget.easyMode,
        recognizedText: _recognizedText,
      ),
      _Stage.processing => AppLoading(
        message: AppLocalizations.of(context)!.voiceProcessing,
      ),
      // 목적지가 분명한 명령은 _respond()에서 곧장 이동하므로, 이 단계에
      // 도달하는 것은 항상 unrecognized(목적지 없음)인 경우뿐이다.
      _Stage.answered => _AnsweredView(
        easyMode: widget.easyMode,
        answerText: _answerText,
        onRetry: _startListening,
      ),
    };
  }
}

class _IdleView extends StatelessWidget {
  const _IdleView({required this.easyMode, required this.onStart});

  final bool easyMode;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            AppLocalizations.of(context)!.voiceIdlePrompt,
            style: AppTextStyles.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          _MicButton(active: false, onTap: onStart, size: easyMode ? 120 : 88),
        ],
      ),
    );
  }
}

class _ListeningView extends StatelessWidget {
  const _ListeningView({required this.easyMode, required this.recognizedText});

  final bool easyMode;
  final String recognizedText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            AppLocalizations.of(context)!.voiceListening,
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xl),
          _MicButton(active: true, onTap: null, size: easyMode ? 120 : 88),
          if (recognizedText.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            Text(
              recognizedText,
              style: AppTextStyles.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// 목적지가 없는 명령(unrecognized)에 대한 안내 — 목적지가 분명한 명령은
/// [VoiceInteractionView._respond]에서 이 화면을 거치지 않고 곧장
/// 이동하므로, 여기서는 "다시 말씀해주세요" 재시도만 제공하면 된다.
class _AnsweredView extends StatelessWidget {
  const _AnsweredView({
    required this.easyMode,
    required this.answerText,
    required this.onRetry,
  });

  final bool easyMode;
  final String answerText;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final buttonSize = easyMode ? AppButtonSize.large : AppButtonSize.standard;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.volume_up_outlined,
            size: 40,
            color: AppColors.primary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            answerText,
            style: AppTextStyles.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: AppLocalizations.of(context)!.voiceRetryButton,
            size: buttonSize,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _MicButton extends StatefulWidget {
  const _MicButton({
    required this.active,
    required this.onTap,
    required this.size,
  });

  final bool active;
  final VoidCallback? onTap;
  final double size;

  @override
  State<_MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<_MicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      button: true,
      label: widget.active ? l10n.voiceListening : l10n.voiceStartSemanticLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          customBorder: const CircleBorder(),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final scale = widget.active
                  ? 1.0 + (_controller.value * 0.12)
                  : 1.0;
              return Transform.scale(scale: scale, child: child);
            },
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.active ? AppColors.primary : AppColors.surface,
                border: widget.active
                    ? null
                    : Border.all(color: AppColors.primary, width: 2),
              ),
              child: Icon(
                Icons.mic,
                size: widget.size * 0.45,
                color: widget.active ? Colors.white : AppColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
