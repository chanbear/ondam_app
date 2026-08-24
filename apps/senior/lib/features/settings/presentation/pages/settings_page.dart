import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../core/easy_mode/easy_mode_provider.dart';
import '../../../../core/location/presentation/providers/region_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../analysis/presentation/providers/analysis_records_notifier.dart';
import '../../../auth/presentation/providers/auth_di_providers.dart';
import '../../../auth/presentation/providers/has_pin_provider.dart';
import '../../../auth/presentation/providers/pin_notifier.dart';
import '../../../auth/presentation/providers/role_notifier.dart';
import '../../../connection/presentation/providers/guardian_links_notifier.dart';
import '../../../onboarding/presentation/widgets/accessibility_settings_form.dart';
import '../../../welfare_center/presentation/providers/welfare_center_notifier.dart';
import '../widgets/language_picker_tile.dart';

/// 설정 — 접근성, 쉬운 모드, 계정(로그아웃/탈퇴). `보호자 알림 설정`과
/// `개인정보 공개 범위 안내`는 각각 `notification`/공지 문구 확정 이후로
/// 미루고 이번에는 노출하지 않는다(있지도 않은 토글을 보여주지 않기 위함).
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  // 로그아웃 자체는 세션만 끝낼 뿐, 다음에 다른 계정으로 로그인했을 때
  // 이전 사용자의 데이터가 남아 있으면 안 된다(ONDAM 2.0 PHASE 29 — 로그아웃
  // 시 사용자별 전역 상태 정리). 아래는 Senior 앱에서 로그인 세션 동안
  // "특정 사용자 계정의 데이터"를 캐시하는 전역 Provider 전수 조사 결과
  // 실제로 노출 위험이 있는 것만 골랐다 — 기기 설정(쉬운 모드/글자
  // 크기/온보딩 완료 여부/카메라·마이크·위치 권한 상태)은 계정이 아니라
  // 기기에 속하는 값이라 의도적으로 제외했다:
  //   - regionProvider/welfareCenterNotifierProvider: 내 지역/경로당 검색
  //     결과 (PHASE 27에서 먼저 발견)
  //   - analysisRecordsProvider: 문서/문자 분석 기록 목록
  //   - guardianLinksProvider: 연결된 보호자 목록
  //   - roleNotifierProvider: 어르신/보호자 역할 목록 — 다음 계정의 역할
  //     판단(auth_redirect.dart)이 이전 계정 값을 참조하지 않도록 함
  //   - hasPinProvider: 다음 계정의 PIN 설정 여부 판단에 쓰이는
  //     `app_router.dart`의 redirect 입력값 — `pin_notifier.dart`가
  //     setPin/resetPin 직후에는 이미 invalidate하지만 로그아웃 시점은
  //     빠져 있었다
  // `sign_out_usecase.dart`의 문서 주석이 이미 명시한 "presentation이
  // 세션 종료 후 메모리 상태를 정리할 책임" 패턴을 그대로 따른다. 인증
  // 흐름 자체(login_notifier/auth_redirect/app_router의 redirect 판단
  // 로직)는 건드리지 않는다 — 여기서는 그 판단에 쓰일 입력값을 무효화만
  // 한다.
  Future<void> _signOut(WidgetRef ref) async {
    final result = await ref.read(signOutUseCaseProvider).call();
    if (result case Ok()) {
      ref.invalidate(regionProvider);
      ref.invalidate(welfareCenterNotifierProvider);
      ref.invalidate(analysisRecordsProvider);
      ref.invalidate(guardianLinksProvider);
      ref.invalidate(roleNotifierProvider);
      ref.invalidate(hasPinProvider);
    }
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
    final easyMode = ref.watch(easyModeProvider);
    final l10n = AppLocalizations.of(context)!;

    return AppScaffold(
      title: l10n.settingsTitle,
      onBack: () => Navigator.of(context).pop(),
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 쉬운 모드/글자 크기/음성 안내/언어를 하나의 카드로 묶는다 —
          // HTML prototype `settings()`의 단일 설정 카드(구분선으로 항목
          // 분리) 구조와 동일. 각 항목 자체의 위젯/로직은 그대로다.
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppSectionHeader(title: l10n.easyModeSectionTitle),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.easyModeTitle),
                  subtitle: Text(l10n.easyModeSubtitle),
                  value: easyMode,
                  onChanged: (_) =>
                      ref.read(easyModeProvider.notifier).toggle(),
                ),
                const Divider(color: AppColors.divider),
                const AccessibilitySettingsForm(),
                const Divider(color: AppColors.divider),
                AppSectionHeader(title: l10n.settingsLanguage),
                const LanguagePickerTile(),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          // 로그아웃/회원탈퇴는 prototype처럼 전체 너비 버튼으로 — 회원탈퇴는
          // destructive variant로 시각적으로 명확히 구분한다(Phase 45-C
          // §11). `_signOut`/`_confirmDeleteAccount` 호출은 그대로다.
          AppButton(
            label: l10n.logout,
            variant: AppButtonVariant.secondary,
            onPressed: () => _signOut(ref),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: l10n.deleteAccount,
            variant: AppButtonVariant.destructive,
            onPressed: () => _confirmDeleteAccount(context, ref),
          ),
        ],
      ),
    );
  }
}
