import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../core/easy_mode/easy_mode_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../voice_assistant/presentation/pages/voice_assistant_page.dart';
import 'home_tab_page.dart';
import 'info_tab_page.dart';
import 'more_tab_page.dart';
import 'records_tab_page.dart';

/// Senior App의 메인 진입점(Auth 이후 첫 화면) — 하단 탭 4개(정보/홈/기록/
/// 더보기)를 로컬 `IndexedStack`으로 전환한다. go_router의 nested
/// StatefulShellRoute 대신 단일 라우트 안에서 탭 상태를 지역적으로 관리하는
/// 방식을 택했다 — 지금 단계에서 각 탭이 별도 URL을 가질 필요가 없고
/// (딥링크 요구사항 없음), 라우터 구조를 더 크게 바꾸지 않기 위함(구현
/// 방식 선택일 뿐 UX 결과는 동일). 필요해지면 나중에 shell route로 전환
/// 가능하다.
///
/// Easy Mode는 탭 4개 구성 자체는 바꾸지 않고(OPEN QUESTIONS 8, DECIDED:
/// 스타일만 확대) `AppBottomNavigation(large: true)`로 아이콘/라벨만
/// 키운다 — 쉬운 모드가 하단 Navigation까지 일관되게 적용된다는 완료
/// 조건(implementation-plan.md Phase 9)을 이걸로 충족한다.
///
/// ONDAM 2.0V — 음성 비서는 홈 탭 카드 중 하나가 아니라, 하단 네비게이션
/// 바로 위에 떠 있는 FAB로 4개 탭 어디서나 접근할 수 있다(요구사항: 위치를
/// 네비게이션바에 맞게 변경). 기존 4탭 구성과 `AppBottomNavigation`은
/// 그대로 유지 — 새 shell/notch 구조를 만들지 않는다.
class HomeShellPage extends ConsumerStatefulWidget {
  const HomeShellPage({super.key});

  @override
  ConsumerState<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends ConsumerState<HomeShellPage> {
  int _index = 1;

  static const _tabs = [
    InfoTabPage(),
    HomeTabPage(),
    RecordsTabPage(),
    MoreTabPage(),
  ];

  void _openVoiceAssistant() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const VoiceAssistantPage()));
  }

  @override
  Widget build(BuildContext context) {
    final easyMode = ref.watch(easyModeProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _index, children: _tabs),
      ),
      floatingActionButton: Semantics(
        button: true,
        label: l10n.voiceAssistantLabel,
        child: easyMode
            ? FloatingActionButton.large(
                onPressed: _openVoiceAssistant,
                tooltip: l10n.voiceAssistantLabel,
                child: const Icon(Icons.mic),
              )
            : FloatingActionButton(
                onPressed: _openVoiceAssistant,
                tooltip: l10n.voiceAssistantLabel,
                child: const Icon(Icons.mic),
              ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: AppBottomNavigation(
        large: easyMode,
        items: [
          AppBottomNavItem(icon: Icons.info_outline, label: l10n.navInfo),
          AppBottomNavItem(icon: Icons.home_outlined, label: l10n.navHome),
          AppBottomNavItem(icon: Icons.history, label: l10n.navRecords),
          AppBottomNavItem(icon: Icons.more_horiz, label: l10n.navMore),
        ],
        currentIndex: _index,
        onTap: (index) => setState(() => _index = index),
      ),
    );
  }
}
