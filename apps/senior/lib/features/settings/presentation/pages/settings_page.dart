import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../core/easy_mode/easy_mode_outline_card.dart';
import '../../../../core/easy_mode/easy_mode_provider.dart';
import '../../../../core/location/presentation/providers/region_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../analysis/presentation/providers/analysis_records_notifier.dart';
import '../../../auth/presentation/providers/auth_di_providers.dart';
import '../../../auth/presentation/providers/has_pin_provider.dart';
import '../../../auth/presentation/providers/pin_notifier.dart';
import '../../../auth/presentation/providers/role_notifier.dart';
import '../../../connection/presentation/pages/guardian_list_page.dart';
import '../../../connection/presentation/providers/guardian_links_notifier.dart';
import '../../../onboarding/presentation/widgets/accessibility_settings_form.dart';
import '../../../welfare_center/presentation/providers/welfare_center_notifier.dart';
import '../widgets/language_picker_tile.dart';
import 'notif_settings_page.dart';

/// 설정 — 접근성, 쉬운 모드, 알림, 계정(로그아웃/탈퇴). `보호자 알림 설정`은
/// 2026-08-31 `NotifSettingsPage`(`users.guardian_notify_enabled` 연동)로
/// 실제 구현됐다 — 더 이상 "있지도 않은 토글" 상태가 아니다.
/// `개인정보 공개 범위 안내`는 여전히 공지 문구 확정 전이라 노출하지 않는다.
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
  //
  // 2026-08-30 — top-level 함수로 분리해 `MoreTabPage`의 독립 "로그아웃"
  // 행(ui-prototype `S("more")`)도 이 로직을 그대로 재사용한다 — 세션 정리
  // 로직을 두 곳에 복제하지 않는다.
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
          // 2026-08-28 — 쉬운 모드일 때는 사용자 승인받은 굵은 테두리 카드
          // (`EasyOutlineCard`)로 바꿔 낀다 — 내용/로직은 동일, 테두리만.
          _buildSettingsBody(
            context: context,
            ref: ref,
            easyMode: easyMode,
            l10n: l10n,
          ),
          const SizedBox(height: AppSpacing.xl),
          // 로그아웃/회원탈퇴는 prototype처럼 전체 너비 버튼으로 — 회원탈퇴는
          // destructive variant로 시각적으로 명확히 구분한다(Phase 45-C
          // §11). `_signOut`/`_confirmDeleteAccount` 호출은 그대로다.
          AppButton(
            label: l10n.logout,
            variant: AppButtonVariant.secondary,
            size: easyMode ? AppButtonSize.large : AppButtonSize.standard,
            onPressed: () => signOutAndClearSession(ref),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: l10n.deleteAccount,
            variant: AppButtonVariant.destructive,
            size: easyMode ? AppButtonSize.large : AppButtonSize.standard,
            onPressed: () => _confirmDeleteAccount(context, ref),
          ),
        ],
      ),
    );
  }

  // 2026-08-30 — ui-prototype `settings()`가 접근성/알림을 하나의 카드에
  // 우겨넣지 않고 구분된 섹션(카드)으로 나눠 보여주는 것에 맞춰, 이 화면도
  // 한 개의 거대한 카드 대신 섹션별 카드로 나눈다 — 내용/Provider 호출은
  // 그대로, 카드 경계만 바뀐다(접근성/알림을 별도 "화면"으로 쪼개지는
  // 않는다는 기존 결정은 유지).
  // 2026-08-28 — 쉬운 모드일 때만 `EasyOutlineCard`(굵은 먹색 테두리)로
  // 바꿔 낀다. 안의 위젯/Provider 호출은 Normal Mode와 완전히 동일 —
  // `AppCard`/`EasyOutlineCard` 둘 다 동일한 `child`를 받는 껍데기 차이뿐.
  Widget _buildSettingsBody({
    required BuildContext context,
    required WidgetRef ref,
    required bool easyMode,
    required AppLocalizations l10n,
  }) {
    Widget wrap(Widget child) =>
        easyMode ? EasyOutlineCard(child: child) : AppCard(child: child);
    // 2026-08-31 — 쉬운 모드에서 카드 테두리/버튼 크기만 바뀌고 항목 글자는
    // 그대로였다(BUG: "쉬움모드에서 설정 글자 안 커짐"). `MoreTabPage`의
    // easy 그리드 타일이 이미 `titleMedium`을 쓰는 것과 맞춰, 이 화면의
    // 스위치/리스트 타이틀도 easyMode일 때 한 단계 큰 스타일로 그린다.
    final titleStyle = easyMode ? AppTextStyles.titleMedium : null;
    final subtitleStyle = easyMode ? AppTextStyles.bodyLarge : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        wrap(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AppSectionHeader(title: l10n.easyModeSectionTitle),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.easyModeTitle, style: titleStyle),
                subtitle: Text(l10n.easyModeSubtitle, style: subtitleStyle),
                value: easyMode,
                activeThumbColor: easyMode ? AppEasyMode.success : null,
                onChanged: (_) => ref.read(easyModeProvider.notifier).toggle(),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        wrap(const AccessibilitySettingsForm()),
        const SizedBox(height: AppSpacing.lg),
        // ui-prototype `S("settings")` — 접근성 바로 아래 보호자 연결
        // 진입 행. 별도 화면을 새로 만들지 않고 `MoreTabPage`에서 이미
        // 쓰는 `GuardianListPage`로 그대로 연결한다(navigation만 추가).
        wrap(
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.family_restroom_outlined),
            title: Text(l10n.guardianListTitle, style: titleStyle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const GuardianListPage())),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // ui-prototype `E("notif-settings")` — 보호자 알림 진입 행. 별도
        // 화면(NotifSettingsPage)으로 뺀다: 접근성 폼과 달리 서버 상태(토글)를
        // 갖는 설정이라 같은 카드 안에 우겨넣지 않는다.
        wrap(
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.notifications_outlined),
            title: Text(l10n.notifSettingsTitle, style: titleStyle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotifSettingsPage()),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        wrap(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AppSectionHeader(title: l10n.settingsLanguage),
              const LanguagePickerTile(),
            ],
          ),
        ),
      ],
    );
  }
}

/// 로그아웃 + 계정-스코프 전역 상태 정리. [SettingsPage]와 `MoreTabPage`의
/// 독립 "로그아웃" 행이 공유한다 — `_signOut` 문서 주석 참고(어떤 Provider를
/// 왜 invalidate하는지).
Future<void> signOutAndClearSession(WidgetRef ref) async {
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
