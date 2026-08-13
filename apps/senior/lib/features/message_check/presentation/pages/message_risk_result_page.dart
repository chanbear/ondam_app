import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../core/widgets/analysis_result_view.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(messageRiskNotifierProvider.notifier).analyze(widget.message);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(messageRiskNotifierProvider);

    return AppScaffold(
      title: '분석 결과',
      onBack: () => Navigator.of(context).pop(),
      body: state.when(
        loading: () => const AppLoading(message: '문자 내용을 확인하고 있어요'),
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
                .read(messageRiskNotifierProvider.notifier)
                .analyze(widget.message),
          );
        },
        data: (result) {
          if (result == null) {
            return const AppLoading(message: '문자 내용을 확인하고 있어요');
          }
          return AnalysisResultView(result: result);
        },
      ),
    );
  }
}
