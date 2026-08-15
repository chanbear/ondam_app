import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:ondam_design_system/ondam_design_system.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../domain/entities/voice_intent.dart';
import '../providers/voice_assistant_di_providers.dart';

enum _Stage { idle, listening, processing, answered }

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
    required this.onDocumentScan,
    required this.onMessageCheck,
    required this.onEmergencyHelp,
  });

  final bool easyMode;
  final VoidCallback onDocumentScan;
  final VoidCallback onMessageCheck;
  final VoidCallback onEmergencyHelp;

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
  VoiceIntent _intent = VoiceIntent.unrecognized;

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
      await _tts.setLanguage('ko-KR');
      await _tts.awaitSpeakCompletion(true);
      if (!mounted) return;
      setState(() {
        _engineReady = available;
        _initError = available ? null : '이 기기에서는 음성 인식을 사용할 수 없어요.';
      });
    } catch (_) {
      if (mounted) setState(() => _initError = '음성 비서를 시작하지 못했어요.');
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  Future<void> _startListening() async {
    setState(() {
      _stage = _Stage.listening;
      _recognizedText = '';
    });
    try {
      await _speech.listen(onResult: _onResult);
    } catch (_) {
      _respond('');
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
    final answer = switch (intent) {
      VoiceIntent.documentScan => '문서 촬영 화면으로 이동할 수 있어요.',
      VoiceIntent.messageCheck => '문자 확인 화면으로 이동할 수 있어요.',
      VoiceIntent.emergencyHelp => '긴급 도움을 보여드릴게요.',
      VoiceIntent.unrecognized =>
        '무슨 말씀인지 잘 이해하지 못했어요. "문서 찍어줘", "문자 확인해줘", "긴급 도움"처럼 말씀해주세요.',
    };
    setState(() {
      _intent = intent;
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

  void _confirmIntent() {
    switch (_intent) {
      case VoiceIntent.documentScan:
        widget.onDocumentScan();
      case VoiceIntent.messageCheck:
        widget.onMessageCheck();
      case VoiceIntent.emergencyHelp:
        widget.onEmergencyHelp();
      case VoiceIntent.unrecognized:
        break;
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
      return const AppLoading(message: '음성 비서를 준비하고 있어요');
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
      _Stage.processing => const AppLoading(message: '요청하신 내용을 확인하고 있어요'),
      _Stage.answered => _AnsweredView(
        easyMode: widget.easyMode,
        answerText: _answerText,
        recognized: _intent != VoiceIntent.unrecognized,
        onReplay: () => _speak(_answerText),
        onRetry: _startListening,
        onConfirm: _confirmIntent,
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
            '마이크를 눌러 말씀해주세요',
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
          Text('듣고 있어요', style: AppTextStyles.titleMedium),
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

class _AnsweredView extends StatelessWidget {
  const _AnsweredView({
    required this.easyMode,
    required this.answerText,
    required this.recognized,
    required this.onReplay,
    required this.onRetry,
    required this.onConfirm,
  });

  final bool easyMode;
  final String answerText;
  final bool recognized;
  final VoidCallback onReplay;
  final VoidCallback onRetry;
  final VoidCallback onConfirm;

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
          if (recognized) ...[
            AppButton(label: '이동하기', size: buttonSize, onPressed: onConfirm),
            const SizedBox(height: AppSpacing.sm),
          ],
          AppButton(
            label: recognized ? '다시 듣기' : '다시 말씀해주세요',
            size: buttonSize,
            onPressed: recognized ? onReplay : onRetry,
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
    return Semantics(
      button: true,
      label: widget.active ? '듣고 있어요' : '말하기 시작',
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
