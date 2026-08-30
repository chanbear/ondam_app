import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../core/easy_mode/easy_mode_outline_card.dart';
import '../../../../core/easy_mode/easy_mode_provider.dart';
import '../../../../core/notification_prefs/presentation/providers/notification_prefs_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// ui-prototype `E("notif-settings")` — 알림 종류별 on/off. "위험 알림"(결과
/// 화면에 위험도를 표시하는 것 자체)은 토글 대상이 아니라 항상 켜져
/// 있고, 실제로 켜고 끌 수 있는 건 "보호자 알림"(위험/주의 결과를 확인했을
/// 때 연결된 보호자에게도 알릴지) 하나뿐이다 — `guardianNotifyEnabledProvider`
/// (`core/notification_prefs`)가 그 상태를 서버(`users.guardian_notify_enabled`)와
/// 동기화한다.
class NotifSettingsPage extends ConsumerWidget {
  const NotifSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final easyMode = ref.watch(easyModeProvider);
    final guardianNotify = ref.watch(guardianNotifyEnabledProvider);
    Widget wrap(Widget child) =>
        easyMode ? EasyOutlineCard(child: child) : AppCard(child: child);

    return AppScaffold(
      title: l10n.notifSettingsTitle,
      onBack: () => Navigator.of(context).pop(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          wrap(
            Row(
              children: [
                const Icon(Icons.warning_amber, color: AppColors.error),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.dangerAlertLabel,
                    style: AppTextStyles.titleMedium,
                  ),
                ),
                Text(
                  l10n.alwaysOnCaption,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          wrap(
            Row(
              children: [
                const Icon(
                  Icons.family_restroom_outlined,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.guardianNotifyLabel,
                    style: AppTextStyles.titleMedium,
                  ),
                ),
                Switch(
                  value: guardianNotify.value ?? true,
                  onChanged: guardianNotify.isLoading
                      ? null
                      : (value) => ref
                            .read(guardianNotifyEnabledProvider.notifier)
                            .setEnabled(value),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
