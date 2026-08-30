import 'package:flutter/material.dart';
import 'package:ondam_models/ondam_models.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/generated/app_localizations.dart';

/// ui-prototype `doc-result`/`msg-result-real` topBar 우측 "공유" 액션 —
/// AI 요약 텍스트를 OS 공유 시트로 내보낸다. 분석 결과 화면 3곳
/// (document_scan_result_page/message_risk_result_page/
/// analysis_record_detail_page)이 이 위젯을 공유해 중복 구현하지 않는다.
class AnalysisShareAction extends StatelessWidget {
  const AnalysisShareAction({super.key, required this.result});

  final AnalysisResult result;

  Future<void> _share() {
    return SharePlus.instance.share(ShareParams(text: result.summary));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      button: true,
      label: l10n.shareButton,
      child: TextButton.icon(
        onPressed: _share,
        icon: const Icon(Icons.ios_share, size: 18),
        label: Text(l10n.shareButton),
      ),
    );
  }
}
