import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/presentation/providers/auth_di_providers.dart';
import '../../../auth/presentation/providers/pin_notifier.dart';
import '../../../notification/presentation/services/push_notification_service.dart';
import '../widgets/language_picker_tile.dart';

/// 설정 — 계정(로그아웃/탈퇴), 위험 알림 설정. 위험 알림 on/off는
/// `notification` feature 도메인이 없어 아직 실제 값을 저장하지 못한다 —
/// 이번 라운드에서는 노출하지 않는다.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  /// FCM token을 먼저 무효화한 뒤 signOut한다 — 순서가 반대이면(Phase 8 실기기
  /// 검증에서 재현된 버그) `signOut()`이 Supabase 세션을 이미 지운 뒤에야
  /// `AuthChangeEvent.signedOut` 리스너가 토큰 삭제를 시도하게 되고,
  /// `fcm_tokens`의 owner-only RLS(`user_id = auth.uid()`)가 인증되지 않은
  /// 요청의 `auth.uid() = null`과 매칭되지 않아 DELETE가 조용히 0 row로
  /// 끝난다. 토큰 무효화 실패는 로그아웃을 막지 않는다 — 로그아웃 자체는
  /// 로컬 세션 종료이지 서버 자원 정리 성공을 전제하지 않는 동작이며,
  /// `invalidateCurrentToken()` 내부에서 이미 실패를 조용히 로그만 한다
  /// (push_notification_service.dart 참고, signedOut 리스너와 동일 정책).
  Future<void> _signOut(WidgetRef ref) async {
    await ref.read(pushNotificationControllerProvider).invalidateCurrentToken();
    await ref.read(signOutUseCaseProvider).call();
  }

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await AppConfirmDialog.show(
      context,
      title: l10n.deleteAccountConfirmTitle,
      message: l10n.deleteAccountConfirmMessage,
      confirmLabel: l10n.deleteAccountConfirmLabel,
      destructive: true,
    );
    if (!confirmed) return;
    await ref.read(pinNotifierProvider.notifier).deleteAccount();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return AppScaffold(
      title: l10n.settingsTitle,
      onBack: () => Navigator.of(context).pop(),
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(title: l10n.settingsLanguage),
          const LanguagePickerTile(),
          const SizedBox(height: AppSpacing.xl),
          AppSectionHeader(title: l10n.accountSectionTitle),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.logout),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _signOut(ref),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              l10n.deleteAccount,
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.error),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _confirmDeleteAccount(context, ref),
          ),
        ],
      ),
    );
  }
}
