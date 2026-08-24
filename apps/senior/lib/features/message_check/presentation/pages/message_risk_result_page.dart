import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../core/easy_mode/easy_mode_provider.dart';
import '../../../../core/widgets/analysis_progress_indicator.dart';
import '../../../../core/widgets/analysis_progress_step.dart';
import '../../../../core/widgets/analysis_result_view.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../analysis/presentation/providers/analysis_records_notifier.dart';
import '../../../voice_assistant/presentation/pages/voice_assistant_page.dart';
import '../../domain/entities/sms_message.dart';
import '../providers/message_risk_notifier.dart';

/// 분석 요청 + 결과 — 백엔드가 아직 없으므로 지금은 항상 `UnavailableFailure`로
/// 귀결된다. `document_scan_result_page.dart`와 동일한 이유로 이를 일반
/// 에러(재시도 유도)가 아니라 "준비 중" 상태로 명확히 구분해서 보여준다
/// (가짜 분석 결과 금지).
class MessageRiskResultPage extends ConsumerStatefulWidget {
  const MessageRiskResultPage({super.key, required this.message});

  final SmsMessage message;

  @override
  ConsumerState<MessageRiskResultPage> createState() =>
      _MessageRiskResultPageState();
}

class _MessageRiskResultPageState extends ConsumerState<MessageRiskResultPage> {
  AnalysisProgressStep _progressStep = AnalysisProgressStep.preparing;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(messageRiskNotifierProvider.notifier).analyze(widget.message);
    });
    _startProgressTicker();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  // 서버가 정밀한 진행률을 주지 않으므로, 단계를 시간 기반으로만 넘긴다 —
  // 마지막 단계(finishing)에서 멈춰 실제 완료 전에 100%처럼 보이지 않는다
  // (ONDAM 2.0 요구사항 21).
  void _startProgressTicker() {
    _progressTimer = Timer.periodic(const Duration(milliseconds: 900), (_) {
      final next = _progressStep.next;
      if (next == null) {
        _progressTimer?.cancel();
        return;
      }
      if (!mounted) return;
      setState(() => _progressStep = next);
    });
  }

  void _openVoiceAssistant() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const VoiceAssistantPage()));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(messageRiskNotifierProvider);
    final easyMode = ref.watch(easyModeProvider);
    final l10n = AppLocalizations.of(context)!;

    return AppScaffold(
      title: l10n.analysisResultTitle,
      onBack: () => Navigator.of(context).pop(),
      body: state.when(
        // A previous AnalysisResult must never remain visible while a new
        // analysis is in flight (riskLevel/reliability from a prior run
        // could otherwise be mistaken for the current one) — AsyncNotifier
        // preserves the previous value across `state = AsyncLoading()` by
        // default, so this must be opted out of explicitly.
        skipLoadingOnRefresh: false,
        loading: () => AnalysisProgressIndicator(step: _progressStep),
        error: (error, _) {
          if (error is UnavailableFailure) {
            return AppEmptyState(
              icon: Icons.hourglass_empty,
              message: error.message,
            );
          }
          final message = error is Failure
              ? error.message
              : l10n.analysisGenericError;
          return AppError(
            message: message,
            onRetry: () => ref
                .read(messageRiskNotifierProvider.notifier)
                .analyze(widget.message),
          );
        },
        data: (result) {
          if (result == null) {
            return AnalysisProgressIndicator(step: _progressStep);
          }
          return AnalysisResultView(
            result: result,
            onAskByVoice: _openVoiceAssistant,
            onConfirm: () =>
                ref.read(analysisRecordsProvider.notifier).confirm(result.id),
            easyMode: easyMode,
          );
        },
      ),
    );
  }
}
