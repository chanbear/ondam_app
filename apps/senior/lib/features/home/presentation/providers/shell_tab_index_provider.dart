import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 홈 탭 셸의 현재 탭 인덱스 — 비즈니스 로직 없는 단순 UI 상태
/// (riverpod.md). `MoreTabPage`의 "알아두면 좋은 정보"처럼 다른 탭에서
/// 정보 탭으로 전환하고 싶을 때만 쓴다(Guardian
/// `shell_tab_index_provider.dart`와 동일한 패턴) — 탭 개수/구조 자체는
/// 바꾸지 않는다.
class ShellTabIndexNotifier extends Notifier<int> {
  @override
  int build() => 1;

  void select(int index) => state = index;
}

final shellTabIndexProvider = NotifierProvider<ShellTabIndexNotifier, int>(
  ShellTabIndexNotifier.new,
);
