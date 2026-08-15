import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../core/easy_mode/easy_mode_provider.dart';
import '../../../../core/widgets/coming_soon_page.dart';
import '../../../document_scan/presentation/pages/document_scan_camera_page.dart';
import '../../../emergency_help/presentation/widgets/emergency_help_sheet.dart';
import '../../../message_check/presentation/pages/message_check_entry_page.dart';
import '../../../onboarding/presentation/pages/onboarding_flow_page.dart';
import '../../../onboarding/presentation/providers/onboarding_status_provider.dart';
import '../../../voice_assistant/presentation/pages/voice_assistant_page.dart';
import '../widgets/easy_mode_home_view.dart';
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

  void _openComingSoon(String title) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ComingSoonPage(title: title)));
  }

  void _openDocumentScan() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const DocumentScanCameraPage()));
  }

  void _openMessageCheck() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const MessageCheckEntryPage()));
  }

  void _openVoiceAssistant() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const VoiceAssistantPage()));
  }

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
        onTap: () => _openComingSoon('경로당 찾기'),
      ),
      HomeFeatureItem(
        icon: Icons.mic_none,
        label: '음성 비서',
        iconColor: AppColors.primary,
        onTap: _openVoiceAssistant,
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

    return easyMode
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
  }
}
