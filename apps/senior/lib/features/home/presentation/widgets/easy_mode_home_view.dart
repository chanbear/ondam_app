import 'package:flutter/material.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../core/widgets/home_feature_card.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Easy Mode home content — Easy Mode is the app's core UX, not a settings
/// toggle (ui-principles.md Senior 8): fewer items (핵심 5개 이하), each a
/// full-width large button, no secondary info cards. 음성 비서와 긴급 도움은
/// 홈에서 동등하게 눈에 띄는 위치에 둔다(ui-spec.md 기존 결정).
class EasyModeHomeView extends StatelessWidget {
  const EasyModeHomeView({
    super.key,
    required this.features,
    required this.onEmergencyTap,
  });

  final List<HomeFeatureItem> features;
  final VoidCallback onEmergencyTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      children: [
        // ui-prototype `E("home")`(Easy 앱) 헤드라인 — Easy Mode 버튼은
        // 서브텍스트/chevron 없이 굵은 라벨만 보여준다(easy-btn 스타일).
        Text(l10n.easyHomeHeadline, style: AppTextStyles.headlineMedium),
        const SizedBox(height: AppSpacing.lg),
        for (final item in features) ...[
          HomeFeatureLargeButton(item: item, showChevron: false),
          const SizedBox(height: AppSpacing.md),
        ],
        // prototype `easyHome()`의 도움 요청 버튼은 다른 easy-btn과 달리
        // solid danger가 아니라 tonal(soft) danger다 — Easy Mode는 "정보량
        // 최소화"가 원칙이라 화면당 가장 눈에 띄는 색을 아껴 쓰기 위함으로
        // 보인다(다른 easy-btn은 흰 배경, primary 항목만 solid green).
        // Normal Mode `_EmergencyButton`(solid)과 의도적으로 다른 스타일.
        Semantics(
          button: true,
          label: l10n.helpRequestLabel,
          child: Material(
            color: AppColors.errorSoft,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              side: const BorderSide(color: AppColors.border),
            ),
            child: InkWell(
              onTap: onEmergencyTap,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Container(
                constraints: const BoxConstraints(minHeight: 76),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.emergency,
                      color: AppColors.error,
                      size: 28,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      l10n.helpRequestLabel,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
