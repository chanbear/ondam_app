import 'package:flutter/material.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

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
class HomeShellPage extends StatefulWidget {
  const HomeShellPage({super.key});

  @override
  State<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends State<HomeShellPage> {
  int _index = 1;

  static const _tabs = [
    InfoTabPage(),
    HomeTabPage(),
    RecordsTabPage(),
    MoreTabPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _index, children: _tabs),
      ),
      bottomNavigationBar: AppBottomNavigation(
        items: const [
          AppBottomNavItem(icon: Icons.info_outline, label: '정보'),
          AppBottomNavItem(icon: Icons.home_outlined, label: '홈'),
          AppBottomNavItem(icon: Icons.history, label: '기록'),
          AppBottomNavItem(icon: Icons.more_horiz, label: '더보기'),
        ],
        currentIndex: _index,
        onTap: (index) => setState(() => _index = index),
      ),
    );
  }
}
