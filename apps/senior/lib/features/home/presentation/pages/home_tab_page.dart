import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../core/easy_mode/easy_mode_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../document_scan/domain/entities/captured_photo.dart';
import '../../../document_scan/presentation/pages/document_scan_camera_page.dart';
import '../../../document_scan/presentation/pages/document_scan_preview_page.dart';
import '../../../emergency_help/presentation/widgets/emergency_help_sheet.dart';
import '../../../message_check/presentation/pages/message_check_entry_page.dart';
import '../../../onboarding/presentation/pages/onboarding_flow_page.dart';
import '../../../onboarding/presentation/providers/onboarding_status_provider.dart';
import '../../../welfare_center/presentation/pages/welfare_center_list_page.dart';
import '../widgets/easy_mode_home_view.dart';
import '../widgets/easy_mode_toggle_card.dart';
import '../widgets/home_feature_card.dart';
import '../widgets/normal_home_view.dart';
import 'records_tab_page.dart';

/// 홈 탭 — Normal/Easy Mode 분기, 핵심 기능 진입점, 긴급 도움. 온보딩을
/// 아직 마치지 않았으면(로컬 플래그) 첫 진입 시 한 번 온보딩으로 안내한다 —
/// 이 넛지는 라우터 redirect가 아니라 화면 레벨 로직이라 Phase 2 Auth 라우팅
/// 구조를 건드리지 않는다.
class HomeTabPage extends ConsumerStatefulWidget {
  const HomeTabPage({super.key});

  @override
  ConsumerState<HomeTabPage> createState() => _HomeTabPageState();
}

class _HomeTabPageState extends ConsumerState<HomeTabPage> {
  bool _onboardingPromptShown = false;

  // ONDAM 2.0 요구사항 11 — 카메라는 촬영한 사진 한 장을 pop으로 돌려줄
  // 뿐이다. 여러 장을 모으는 진짜 시작점은 미리보기 화면이므로, 첫 촬영
  // 직후 그 화면으로 넘어간다("추가 촬영"도 같은 카메라 화면을 재사용).
  Future<void> _openDocumentScan() async {
    final photo = await Navigator.of(context).push<CapturedPhoto>(
      MaterialPageRoute(builder: (_) => const DocumentScanCameraPage()),
    );
    if (photo == null || !mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DocumentScanPreviewPage(photos: [photo]),
      ),
    );
  }

  void _openMessageCheck() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const MessageCheckEntryPage()));
  }

  void _openWelfareCenter() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const WelfareCenterListPage()));
  }

  // 기록 탭은 IndexedStack으로 관리되는 별도 탭이라(HomeShellPage), 여기서는
  // 탭 인덱스를 바꾸는 대신 같은 RecordsTabPage를 뒤로가기 가능한 화면으로
  // 한 번 더 push한다 — 탭 구조/상태 관리 방식은 건드리지 않는다.
  void _openRecords() {
    final l10n = AppLocalizations.of(context)!;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AppScaffold(
          title: l10n.myRecordsTitle,
          onBack: () => Navigator.of(context).pop(),
          body: const RecordsTabPage(),
        ),
      ),
    );
  }

  // 음성 비서는 더 이상 이 그리드의 카드가 아니다 — 하단 네비게이션 바로
  // 위 FAB로 이전됨(ONDAM 2.0V, HomeShellPage 참고).
  HomeFeatureItem _documentItem(AppLocalizations l10n) => HomeFeatureItem(
    icon: Icons.document_scanner_outlined,
    label: l10n.documentReadLabel,
    iconColor: AppColors.primary,
    onTap: _openDocumentScan,
  );

  HomeFeatureItem _messageItem(AppLocalizations l10n) => HomeFeatureItem(
    icon: Icons.sms_outlined,
    label: l10n.messageCheckLabel,
    iconColor: AppColors.primary,
    onTap: _openMessageCheck,
  );

  HomeFeatureItem _welfareItem(AppLocalizations l10n) => HomeFeatureItem(
    icon: Icons.place_outlined,
    label: l10n.welfareCenterTitle,
    iconColor: AppColors.secondary,
    onTap: _openWelfareCenter,
  );

  HomeFeatureItem _recordsItem(AppLocalizations l10n) => HomeFeatureItem(
    icon: Icons.history,
    label: l10n.myRecordsTitle,
    iconColor: AppColors.primary,
    onTap: _openRecords,
  );

  // Normal Mode는 prototype `home()`의 4개 그리드(문서/문자/경로당/기록)를
  // 그대로 따른다.
  List<HomeFeatureItem> _normalFeatures(AppLocalizations l10n) => [
    _documentItem(l10n),
    _messageItem(l10n),
    _welfareItem(l10n),
    _recordsItem(l10n),
  ];

  // Easy Mode는 prototype `easyHome()`을 따라 3개만 노출한다(경로당 찾기
  // 제외) — "핵심 5개 이하, 정보량 최소화" 원칙(easy_mode_home_view.dart
  // 기존 doc comment)과 일치.
  List<HomeFeatureItem> _easyFeatures(AppLocalizations l10n) => [
    _documentItem(l10n),
    _messageItem(l10n),
    _recordsItem(l10n),
  ];

  @override
  Widget build(BuildContext context) {
    final easyMode = ref.watch(easyModeProvider);
    final onboardingCompleted = ref.watch(onboardingStatusProvider);
    final l10n = AppLocalizations.of(context)!;

    if (onboardingCompleted == false && !_onboardingPromptShown) {
      _onboardingPromptShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const OnboardingFlowPage()));
      });
    }

    // 쉬운 모드 토글은 일반/쉬운 모드 홈 화면 모두 상단에 동일하게 둔다
    // (ONDAM 2.0 요구사항 33) — 음성비서 FAB(HomeShellPage, centerFloat)
    // 위치를 침범하지 않는다. 긴급 도움은 이제 FAB가 아니라 각 View 안에
    // prototype과 동일하게 인라인 버튼으로 배치된다(Phase 44).
    final content = easyMode
        ? EasyModeHomeView(
            features: _easyFeatures(l10n),
            onEmergencyTap: () => EmergencyHelpSheet.show(context),
          )
        : NormalHomeView(
            features: _normalFeatures(l10n),
            onEmergencyTap: () => EmergencyHelpSheet.show(context),
          );

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            0,
          ),
          child: EasyModeToggleCard(),
        ),
        Expanded(child: content),
      ],
    );
  }
}
