import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 홈 탭 셸의 현재 탭 인덱스 — 비즈니스 로직 없는 단순 UI 상태
/// (riverpod.md). `HomeTabPage`의 "최근 알림 전체보기"처럼 다른 탭에서
/// 특정 탭으로 전환하고 싶을 때만 쓴다(Guardian UI Application Round 1
/// §6) — 탭 개수/구조 자체는 바꾸지 않는다(§13).
class ShellTabIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) => state = index;
}

final shellTabIndexProvider = NotifierProvider<ShellTabIndexNotifier, int>(
  ShellTabIndexNotifier.new,
);
