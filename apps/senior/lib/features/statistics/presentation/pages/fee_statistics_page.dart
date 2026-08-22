import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../analysis/presentation/providers/analysis_records_notifier.dart';

/// 요금 통계 (PHASE 37) — 본인의 `analysis_results` 중 금액을 신뢰성 있게
/// 추출한 문서 기록만으로 계산한다. 데이터 소스/계산 로직 모두 새로 만들지
/// 않고 기존 `analysis` feature의 `analysisRecordsProvider`
/// (`FeeStatisticsCalculator`는 ondam_models, `AppFeeStatisticsSection`은
/// ondam_design_system — Guardian과 동일)를 그대로 재사용한다.
class FeeStatisticsPage extends ConsumerWidget {
  const FeeStatisticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analysisRecordsProvider);

    return AppScaffold(
      title: '요금 통계',
      onBack: () => Navigator.of(context).pop(),
      scrollable: true,
      body: state.when(
        loading: () => const AppLoading(message: '요금 통계를 불러오고 있어요'),
        error: (error, _) {
          final message = error is Failure
              ? error.message
              : '요금 통계를 불러오는 중 문제가 발생했어요.';
          return AppError(
            message: message,
            onRetry: () => ref.invalidate(analysisRecordsProvider),
          );
        },
        data: (records) => AppFeeStatisticsSection(records: records),
      ),
    );
  }
}
