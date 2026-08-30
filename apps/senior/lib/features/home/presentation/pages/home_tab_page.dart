import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../core/easy_mode/easy_mode_provider.dart';
import '../../../../core/voice_guide/voice_guide_provider.dart';
import '../../../../core/voice_guide/voice_guide_service.dart';
import '../../../../core/widgets/home_feature_card.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../document_scan/presentation/pages/document_scan_start_page.dart';
import '../../../emergency_help/presentation/widgets/emergency_help_sheet.dart';
import '../../../message_check/presentation/pages/message_check_entry_page.dart';
import '../../../onboarding/presentation/pages/onboarding_flow_page.dart';
import '../../../onboarding/presentation/providers/onboarding_status_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../welfare_center/presentation/pages/welfare_center_list_page.dart';
import '../widgets/easy_mode_home_view.dart';
import '../widgets/easy_mode_toggle_card.dart';
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
  bool _voiceGuideSpoken = false;
  // dispose()에서는 ref.read()가 안전하지 않다(ConsumerState가 이미
  // unmount 중일 수 있음) — initState에서 미리 읽어 필드에 저장해둔다.
  late final VoiceGuideService _voiceGuideService;

  @override
  void initState() {
    super.initState();
    _voiceGuideService = ref.read(voiceGuideServiceProvider);
  }

  @override
  void dispose() {
    _voiceGuideService.stop();
    super.dispose();
  }

  // ui-prototype `S("doc-start")` — 홈에서 곧장 카메라로 가지 않고, 촬영/
  // 불러오기 두 갈래 + 촬영 팁을 보여주는 진입 화면을 먼저 거친다. 카메라
  // 쪽 흐름(사진 한 장을 pop으로 돌려받아 미리보기로 넘기는 것)은
  // [DocumentScanStartPage]가 그대로 맡는다.
  void _openDocumentScan() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const DocumentScanStartPage()));
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
    subtitle: l10n.documentReadSubtitle,
    iconColor: AppColors.primary,
    onTap: _openDocumentScan,
  );

  HomeFeatureItem _messageItem(AppLocalizations l10n) => HomeFeatureItem(
    icon: Icons.sms_outlined,
    label: l10n.messageCheckLabel,
    subtitle: l10n.messageCheckSubtitle,
    iconColor: AppColors.primary,
    onTap: _openMessageCheck,
  );

  // 홈 카드 라벨은 ui-prototype 2026-08-29 결정에 따라 "경로당 찾기"보다
  // 넓은 "공공시설 찾기"를 쓴다 — 실제 이동 대상(WelfareCenterListPage)의
  // 화면 타이틀(welfareCenterTitle)은 그대로 "경로당 찾기"로 둔다(그
  // 화면은 여전히 경로당만 검색하므로).
  HomeFeatureItem _welfareItem(AppLocalizations l10n) => HomeFeatureItem(
    icon: Icons.place_outlined,
    label: l10n.publicFacilitySearchLabel,
    subtitle: l10n.publicFacilitySearchSubtitle,
    iconColor: AppColors.secondary,
    onTap: _openWelfareCenter,
  );

  HomeFeatureItem _recordsItem(AppLocalizations l10n) => HomeFeatureItem(
    icon: Icons.history,
    label: l10n.myRecordsTitle,
    iconColor: AppColors.primary,
    onTap: _openRecords,
  );

  // Modern Care 리디자인(2026-08-26, 사용자 승인) — 긴급 도움을 그리드
  // 바깥 별도 strip이 아니라 그리드 안 카드로 넣고, error 톤 아이콘으로만
  // 구분한다. 대신 "내 기록"은 그리드에서 빠지고 하단 네비 "기록" 탭으로만
  // 접근한다(디자인 제안 Before/After #4, 아이콘 배경 error 톤 참고).
  HomeFeatureItem _emergencyItem(AppLocalizations l10n) => HomeFeatureItem(
    icon: Icons.phone_in_talk,
    label: l10n.emergencyHelpRequestLabel,
    subtitle: l10n.emergencyHelpRequestSubtitle,
    iconColor: AppColors.error,
    onTap: () => EmergencyHelpSheet.show(context),
  );

  List<HomeFeatureItem> _normalFeatures(AppLocalizations l10n) => [
    _documentItem(l10n),
    _messageItem(l10n),
    _welfareItem(l10n),
    _emergencyItem(l10n),
  ];

  // 2026-08-28 — ui-prototype에서 Easy 홈을 문서읽기/문자확인/경로당찾기/
  // 말로물어보기 4개 전체너비 버튼으로 확정(사용자 승인) — 경로당을 다시
  // 포함시켜 맞춘다. 말로 물어보기는 이 앱에서 이미 하단 네비 옆 FAB로
  // 옮겨져 있어(HomeShellPage) 그리드에는 넣지 않는다.
  List<HomeFeatureItem> _easyFeatures(AppLocalizations l10n) => [
    _documentItem(l10n),
    _messageItem(l10n),
    _welfareItem(l10n),
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

    if (!_voiceGuideSpoken) {
      _voiceGuideSpoken = true;
      final guideText = easyMode
          ? l10n.homeVoiceGuideEasy
          : l10n.homeVoiceGuideNormal;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        speakScreenGuide(ref, guideText);
      });
    }

    // 쉬운 모드 토글은 일반/쉬운 모드 홈 화면 모두 상단에 동일하게 둔다
    // (ONDAM 2.0 요구사항 33) — 음성비서 FAB(HomeShellPage, centerFloat)
    // 위치를 침범하지 않는다. Easy Mode는 여전히 별도 tonal 도움 버튼을
    // 쓰지만, Normal Mode는 Modern Care 리디자인 이후 긴급 도움이
    // `_emergencyItem` 그리드 카드 하나로 합쳐져 별도 버튼이 필요 없다.
    final content = easyMode
        ? EasyModeHomeView(
            features: _easyFeatures(l10n),
            onEmergencyTap: () => EmergencyHelpSheet.show(context),
          )
        : NormalHomeView(features: _normalFeatures(l10n));

    return Column(
      children: [
        // 인사말은 Normal Mode 전용(ui-prototype `S("home")`에만 있고
        // Easy 앱의 `E("home")`에는 없다) — 실제 저장된 이름(profileProvider)
        // 이 있을 때만 보여주고, 아직 입력 전(null)이거나 로딩/에러 중이면
        // 조용히 생략한다(빈 값을 지어내지 않는다).
        if (!easyMode)
          _HomeGreeting(name: ref.watch(profileProvider).value?.name),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            0,
          ),
          child: const EasyModeToggleCard(),
        ),
        Expanded(child: content),
      ],
    );
  }
}

/// ui-prototype `S("home")` 상단 인사말("OOO님, 안녕하세요!" + 한 줄 설명).
/// [name]이 null이면(프로필 미입력) 아무것도 그리지 않는다.
class _HomeGreeting extends StatelessWidget {
  const _HomeGreeting({required this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    final name = this.name;
    if (name == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.homeGreetingWithName(name),
            style: AppTextStyles.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.homeGreetingSubtitle,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
