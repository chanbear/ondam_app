import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../core/easy_mode/easy_mode_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// ui-prototype `E("msg-guardian-notice")` — 위험/주의 문자 결과를 확인하고
/// `MessageRiskNotifier.notifyGuardianIfNeeded()`가 실제로 보호자에게 알림을
/// 보내는 데 성공했을 때만 이 화면으로 온다(정직하게 안내 원칙 — 보내지
/// 못했으면 이 화면 자체가 뜨지 않는다). 보호자 이름은 클라이언트에서 알 수
/// 없어(guardian_list_page.dart와 동일한 이유) 문구에 이름을 넣지 않는다.
class MessageGuardianNoticePage extends ConsumerWidget {
  const MessageGuardianNoticePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final easyMode = ref.watch(easyModeProvider);
    return AppScaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.successSoft,
              child: Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 32,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.messageGuardianNoticeTitle,
              style: AppTextStyles.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.messageGuardianNoticeBody,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: l10n.goHomeButton,
              size: easyMode ? AppButtonSize.large : AppButtonSize.standard,
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
            ),
          ],
        ),
      ),
    );
  }
}
