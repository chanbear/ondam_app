import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../core/easy_mode/easy_mode_provider.dart';
import '../../../../core/l10n/failure_l10n.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/emergency_help_di_providers.dart';

/// 긴급 도움 모달 — 112/119/110/120을 실제 다이얼러로 연결한다
/// (`url_launcher`).
///
/// 2026-08-29 product decision(ui-prototype `S("emergency")` decision 참고):
/// 사용자 요청으로 SOS 구성을 보호자 전화/119/112에서 112·119·110·120 4개
/// 공공 긴급/상담 번호로 교체. 112(경찰)·119(소방·구급)는 emergency(빨강)
/// 톤으로 다급함을 강조하고, 110(정부민원안내)·120(다산콜센터·지역상담)은
/// secondary(중립) 톤으로 구분한다.
class EmergencyHelpSheet extends ConsumerWidget {
  const EmergencyHelpSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (context) => const EmergencyHelpSheet(),
    );
  }

  Future<void> _call(BuildContext context, WidgetRef ref, String number) async {
    final result = await ref.read(callPhoneUseCaseProvider).call(number);
    if (!context.mounted) return;
    switch (result) {
      case Ok():
        break;
      case Err(:final failure):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizeFailureMessage(context, failure.message)),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final easyMode = ref.watch(easyModeProvider);
    final buttonSize = easyMode ? AppButtonSize.large : AppButtonSize.standard;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ui-prototype `S("emergency")` — 상단 큰 아이콘 배지 + 중앙정렬
            // 타이틀.
            const CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.emergencySoft,
              child: Icon(
                Icons.crisis_alert,
                color: AppColors.emergency,
                size: 32,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.emergencyHelpTitle,
              style: AppTextStyles.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: l10n.emergency112Label,
              variant: AppButtonVariant.emergency,
              size: buttonSize,
              icon: Icons.local_police,
              onPressed: () => _call(context, ref, '112'),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: l10n.emergency119Label,
              variant: AppButtonVariant.emergency,
              size: buttonSize,
              icon: Icons.local_fire_department,
              onPressed: () => _call(context, ref, '119'),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: l10n.govComplaintLabel,
              variant: AppButtonVariant.secondary,
              size: buttonSize,
              icon: Icons.support_agent,
              onPressed: () => _call(context, ref, '110'),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: l10n.dasanCallCenterLabel,
              variant: AppButtonVariant.secondary,
              size: buttonSize,
              icon: Icons.phone_in_talk,
              onPressed: () => _call(context, ref, '120'),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: l10n.cancelButton,
              variant: AppButtonVariant.text,
              size: buttonSize,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
