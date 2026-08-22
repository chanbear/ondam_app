import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../core/easy_mode/easy_mode_provider.dart';
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

  // 음성 비서는 더 이상 이 그리드의 카드가 아니다 — 하단 네비게이션 바로
  // 위 FAB로 이전됨(ONDAM 2.0V, HomeShellPage 참고).
  List<HomeFeatureItem> _features() {
    return [
      HomeFeatureItem(
        icon: Icons.document_scanner_outlined,
        label: '문서 촬영',
        iconColor: AppColors.primary,
        onTap: _openDocumentScan,
      ),
      HomeFeatureItem(
        icon: Icons.sms_outlined,
        label: '문자 확인',
        iconColor: AppColors.primary,
        onTap: _openMessageCheck,
      ),
      HomeFeatureItem(
        icon: Icons.place_outlined,
        label: '경로당 찾기',
        iconColor: AppColors.secondary,
        onTap: _openWelfareCenter,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final easyMode = ref.watch(easyModeProvider);
    final onboardingCompleted = ref.watch(onboardingStatusProvider);

    if (onboardingCompleted == false && !_onboardingPromptShown) {
      _onboardingPromptShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const OnboardingFlowPage()));
      });
    }

    final features = _features();

    // 쉬운 모드 토글은 일반/쉬운 모드 홈 화면 모두 상단에 동일하게 둔다
    // (ONDAM 2.0 요구사항 33) — 음성비서 FAB(HomeShellPage, centerFloat)와
    // 긴급도움 FAB(아래, 우하단) 위치를 침범하지 않는다.
    final content = easyMode
        ? EasyModeHomeView(
            features: features,
            onEmergencyTap: () => EmergencyHelpSheet.show(context),
          )
        : Stack(
            children: [
              NormalHomeView(features: features),
              Positioned(
                right: 0,
                bottom: 0,
                child: FloatingActionButton(
                  backgroundColor: AppColors.error,
                  tooltip: '긴급 도움',
                  onPressed: () => EmergencyHelpSheet.show(context),
                  child: const Icon(Icons.emergency, color: Colors.white),
                ),
              ),
            ],
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
