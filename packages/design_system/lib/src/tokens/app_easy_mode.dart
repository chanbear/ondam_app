import 'package:flutter/material.dart';

/// Easy Mode enlargement factor for shared shell widgets (currently only
/// [AppBottomNavigation]) — implementation-plan.md §2 "쉬운 모드 배율 헬퍼".
/// Screen-specific Easy Mode content (e.g. `EasyModeHomeView`) uses its own
/// dedicated large-button widgets instead of scaling shared tokens.
///
/// ui-prototype `[data-easy="true"]`의 Easy Mode 전용 오버라이드 —
/// 원색을 더 채도 높게 조정한다(레이아웃/배치는 그대로). "굵은 먹색
/// 테두리"였던 outlineWidth/outlineColor는 2026-08-29 ui-prototype에서
/// 삭제되어 여기서도 제거했다 — Easy Mode 카드도 이제 Normal Mode와 같은
/// [AppColors.border](1px)를 쓴다. `AppColors`의 success/warning/error/
/// emergency는 Normal Mode에서도 쓰이므로 값을 직접 바꾸지 않고, Easy
/// Mode 전용 오버라이드를 여기 별도로 둔다.
abstract final class AppEasyMode {
  static const double navIconScale = 1.3;
  static const double navBarHeight = 80;

  static const Color success = Color(0xFF0F9D4E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFE53228);
  static const Color emergency = Color(0xFFE5484D);
}
