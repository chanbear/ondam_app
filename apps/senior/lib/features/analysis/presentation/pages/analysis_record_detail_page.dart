import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_design_system/ondam_design_system.dart';
import 'package:ondam_models/ondam_models.dart';

import '../../../../core/easy_mode/easy_mode_provider.dart';
import '../../../../core/widgets/analysis_result_view.dart';
import '../../../../core/widgets/analysis_share_action.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../voice_assistant/presentation/pages/voice_assistant_page.dart';
import '../providers/analysis_records_notifier.dart';

/// Records-tab 전용 상세 화면 — 새 결과 UI를 만들지 않고 `document_scan`/
/// `message_check`와 동일하게 [AnalysisResultView]를 그대로 재사용한다
/// (PHASE 10 §7). 이미 완료된 과거 기록을 보여줄 뿐이라 분석 요청/재시도
/// 로직은 없다 — `message_risk_result_page.dart`와 달리 loading/error 상태가
/// 존재하지 않는다(레코드는 이미 DB에서 로드 완료된 상태로 전달됨).
class AnalysisRecordDetailPage extends ConsumerWidget {
  const AnalysisRecordDetailPage({super.key, required this.result});

  final AnalysisResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final easyMode = ref.watch(easyModeProvider);
    final l10n = AppLocalizations.of(context)!;

    return AppScaffold(
      title: l10n.analysisResultTitle,
      onBack: () => Navigator.of(context).pop(),
      headerActions: [AnalysisShareAction(result: result)],
      body: AnalysisResultView(
        result: result,
        onAskByVoice: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const VoiceAssistantPage())),
        onConfirm: () =>
            ref.read(analysisRecordsProvider.notifier).confirm(result.id),
        easyMode: easyMode,
      ),
    );
  }
}
