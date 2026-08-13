import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_design_system/ondam_design_system.dart';
import 'package:ondam_models/ondam_models.dart';

import '../../domain/entities/captured_photo.dart';
import '../providers/analysis_notifier.dart';

/// 분석 요청 + 결과 — 백엔드가 아직 없으므로 지금은 항상 `UnavailableFailure`로
/// 귀결된다. 이를 일반 에러(재시도 유도)가 아니라 "준비 중" 상태로 명확히
/// 구분해서 보여준다(가짜 분석 결과 금지, Phase 4 규칙).
class DocumentScanResultPage extends ConsumerStatefulWidget {
  const DocumentScanResultPage({super.key, required this.photo});

  final CapturedPhoto photo;

  @override
  ConsumerState<DocumentScanResultPage> createState() =>
      _DocumentScanResultPageState();
}

class _DocumentScanResultPageState
    extends ConsumerState<DocumentScanResultPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analysisNotifierProvider.notifier).analyze(widget.photo);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(analysisNotifierProvider);

    return AppScaffold(
      title: '분석 결과',
      onBack: () => Navigator.of(context).pop(),
      body: state.when(
        loading: () => const AppLoading(message: '문서 내용을 확인하고 있어요'),
        error: (error, _) {
          if (error is UnavailableFailure) {
            return AppEmptyState(
              icon: Icons.hourglass_empty,
              message: error.message,
            );
          }
          final message = error is Failure ? error.message : '분석 중 문제가 발생했어요.';
          return AppError(
            message: message,
            onRetry: () => ref
                .read(analysisNotifierProvider.notifier)
                .analyze(widget.photo),
          );
        },
        data: (result) {
          if (result == null) {
            return const AppLoading(message: '문서 내용을 확인하고 있어요');
          }
          return AnalysisResultView(result: result);
        },
      ),
    );
  }
}

class AnalysisResultView extends StatelessWidget {
  const AnalysisResultView({super.key, required this.result});

  final AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final risk = result.riskLevel;
    final structuredFields = result.structuredFields;

    return ListView(
      children: [
        AppConfidenceIndicator(level: result.reliability),
        const SizedBox(height: AppSpacing.lg),
        if (risk != null) ...[
          AppRiskBadge(level: risk),
          const SizedBox(height: AppSpacing.md),
        ],
        AppSectionHeader(title: '요약'),
        Text(result.summary, style: AppTextStyles.bodyLarge),
        if (structuredFields != null && structuredFields.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          AppSectionHeader(title: '문서 정보'),
          for (final entry in structuredFields.entries)
            AppInfoRow(label: entry.key, value: '${entry.value}'),
        ],
      ],
    );
  }
}
