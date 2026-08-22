import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_design_system/ondam_design_system.dart';
import 'package:ondam_models/ondam_models.dart';

import '../../../../core/easy_mode/easy_mode_provider.dart';
import '../../../../core/widgets/analysis_progress_indicator.dart';
import '../../../../core/widgets/analysis_progress_step.dart';
import '../../../../core/widgets/analysis_result_view.dart';
import '../../../analysis/presentation/pages/analysis_record_detail_page.dart';
import '../../../analysis/presentation/providers/analysis_records_notifier.dart';
import '../../../analysis/presentation/widgets/analysis_record_card.dart';
import '../../../voice_assistant/presentation/pages/voice_assistant_page.dart';
import '../../domain/entities/captured_photo.dart';
import '../providers/document_scan_di_providers.dart';

/// 분석 요청 + 결과 — ONDAM 2.0 요구사항 11(다중 문서 촬영)에 맞춰 여러
/// 장을 순서대로 분석한다. 기존 `analyze-document`(단일 사진) 계약은 전혀
/// 바꾸지 않고, 이 usecase를 사진 수만큼 반복 호출한다("단일 문서 분석을
/// 여러 번 호출하는 방식" — 근거 없이 API 계약을 바꾸지 않기 위한 선택).
///
/// 사진이 1장뿐이면(기존 단일 문서 흐름) 결과를 곧장 [AnalysisResultView]
/// 로 보여준다 — 기존 사용자 경험을 그대로 유지한다. 2장 이상이면 각각의
/// 결과를 [AnalysisRecordCard] 목록으로 보여주고, 카드를 누르면 기존
/// [AnalysisRecordDetailPage]로 상세를 연다(새 결과 위젯을 만들지 않고
/// "기록" 화면의 기존 컴포넌트를 그대로 재사용).
class DocumentScanResultPage extends ConsumerStatefulWidget {
  const DocumentScanResultPage({super.key, required this.photos})
    : assert(photos.length > 0, '분석할 사진이 최소 1장 있어야 한다');

  final List<CapturedPhoto> photos;

  @override
  ConsumerState<DocumentScanResultPage> createState() =>
      _DocumentScanResultPageState();
}

class _DocumentScanResultPageState
    extends ConsumerState<DocumentScanResultPage> {
  AnalysisProgressStep _progressStep = AnalysisProgressStep.preparing;
  Timer? _progressTimer;

  bool _loading = true;
  int _currentIndex = 0;
  final List<AnalysisResult> _results = [];
  Failure? _failure;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _analyzeAll());
    _startProgressTicker();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  // 서버가 정밀한 진행률을 주지 않으므로, 단계를 시간 기반으로만 넘긴다 —
  // 마지막 단계(finishing)에서 멈춰 실제 완료 전에 100%처럼 보이지 않는다
  // (ONDAM 2.0 요구사항 12). 여러 장을 분석하는 동안에도 배치 전체를
  // 대표하는 하나의 진행 표시로 충분하다 — 사진별로 새로 시작하지 않는다.
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

  Future<void> _analyzeAll() async {
    setState(() {
      _loading = true;
      _failure = null;
      _results.clear();
      _currentIndex = 0;
    });

    for (var i = 0; i < widget.photos.length; i++) {
      if (!mounted) return;
      setState(() => _currentIndex = i);

      final result = await ref
          .read(analyzeDocumentUseCaseProvider)
          .call(widget.photos[i]);
      if (!mounted) return;

      switch (result) {
        case Ok(:final value):
          setState(() => _results.add(value));
        case Err(:final failure):
          setState(() {
            _failure = failure;
            _loading = false;
          });
          return;
      }
    }

    setState(() => _loading = false);
  }

  void _openVoiceAssistant() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const VoiceAssistantPage()));
  }

  @override
  Widget build(BuildContext context) {
    final easyMode = ref.watch(easyModeProvider);

    return AppScaffold(
      title: '분석 결과',
      onBack: () => Navigator.of(context).pop(),
      body: _buildBody(easyMode),
    );
  }

  Widget _buildBody(bool easyMode) {
    if (_loading) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.photos.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                '${_currentIndex + 1}/${widget.photos.length} 문서 분석 중',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          AnalysisProgressIndicator(step: _progressStep),
        ],
      );
    }

    final failure = _failure;
    if (failure != null) {
      if (failure is UnavailableFailure) {
        return AppEmptyState(
          icon: Icons.hourglass_empty,
          message: failure.message,
        );
      }
      return AppError(message: failure.message, onRetry: _analyzeAll);
    }

    if (_results.length == 1) {
      final result = _results.first;
      return AnalysisResultView(
        result: result,
        onAskByVoice: _openVoiceAssistant,
        onConfirm: () =>
            ref.read(analysisRecordsProvider.notifier).confirm(result.id),
        easyMode: easyMode,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text('문서 ${_results.length}건을 분석했어요', style: AppTextStyles.titleMedium),
        const SizedBox(height: AppSpacing.md),
        for (final result in _results) ...[
          AnalysisRecordCard(
            result: result,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AnalysisRecordDetailPage(result: result),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}
