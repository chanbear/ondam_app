import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../analysis/presentation/pages/analysis_record_detail_page.dart';
import '../../../analysis/presentation/providers/analysis_records_notifier.dart';
import '../../../analysis/presentation/widgets/analysis_record_card.dart';
import 'home_feature_card.dart';

/// Normal Mode home content — full card grid + inline 긴급 도움 + "최근 기록"
/// 미리보기(Phase 44, PHASE 40 프로토타입의 `home()` 정보 순서를 그대로
/// 따름: 기능 그리드 → 긴급 도움 → 최근 기록). 최근 기록은 이미 기록 탭이
/// 쓰는 [analysisRecordsProvider]를 그대로 읽기만 한다 — 새 데이터소스를
/// 만들지 않는다. 기록이 없거나 아직 로딩/에러 중이면 섹션 자체를 숨긴다
/// (빈 영역 노출 금지 원칙, ui-principles.md) — 홈 화면의 부가 미리보기라
/// 기록 탭과 달리 별도 로딩/에러 UI를 두지 않는다.
class NormalHomeView extends ConsumerWidget {
  const NormalHomeView({
    super.key,
    required this.features,
    required this.onEmergencyTap,
  });

  final List<HomeFeatureItem> features;
  final VoidCallback onEmergencyTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentRecords =
        ref.watch(analysisRecordsProvider).value?.take(2).toList() ?? const [];
    final l10n = AppLocalizations.of(context)!;

    return ListView(
      children: [
        AppSectionHeader(title: l10n.coreFeaturesTitle),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1.1,
          children: [for (final item in features) HomeFeatureCard(item: item)],
        ),
        const SizedBox(height: AppSpacing.md),
        _EmergencyButton(onTap: onEmergencyTap),
        const SizedBox(height: AppSpacing.xl),
        if (recentRecords.isNotEmpty) ...[
          AppSectionHeader(title: l10n.recentRecordsTitle),
          for (final record in recentRecords)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AnalysisRecordCard(
                result: record,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AnalysisRecordDetailPage(result: record),
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

/// prototype `.emergency-btn`(전체 너비, 그리드 바로 아래, 고정 위치 아님)과
/// 동일한 배치 — solid danger 색(soft/tonal이 아님, Easy Mode의 도움 요청
/// 버튼과 의도적으로 다름). Design System에 이 색 조합(solid error) variant가
/// 없어 새로 만들지 않고 `AppColors.error` 토큰만으로 여기서 직접 구성한다.
class _EmergencyButton extends StatelessWidget {
  const _EmergencyButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: AppLocalizations.of(context)!.emergencyHelpRequestLabel,
      child: Material(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.phone_in_talk, color: Colors.white),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  AppLocalizations.of(context)!.emergencyHelpRequestLabel,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
