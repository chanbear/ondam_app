import 'package:flutter/material.dart';

/// Color tokens — synced to `ui-prototype/css/tokens.css` (2026-08-30, 사용자
/// 승인 — Modern Care(`prototype/redesign/`)가 아니라 이번 세션에서 다듬은
/// `ui-prototype/`을 소스로 채택). `primary`는 easy-mode-test 브랜치 실제
/// 블루(`#3D6BF5`)로 이전 `#1D61E7`에서 교체됐고, `background`/`border`도
/// 순백 배경 + 차가운 회색 경계선으로 바뀌었다.
///
/// NOTE: `*Dark` pair는 ui-prototype에도 라이트모드 값만 있어 이전 값을
/// 그대로 유지한다.
abstract final class AppColors {
  static const Color primary = Color(0xFF3D6BF5);
  static const Color secondary = Color(0xFF12A594);

  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF14151A);
  static const Color textSecondary = Color(0xFF585C68);
  static const Color textDisabled = Color(0xFFBDBDBD);

  static const Color border = Color(0xFFE2E5EA);
  static const Color divider = Color(0xFFE2E5EA);

  /// 카드 선택 상태 등 `border`보다 한 단계 진한 2차 경계선 — 입력창
  /// 기본 테두리, 미선택 chip 등에 쓴다. ui-prototype에는 별도 토큰이 없어
  /// 새 `border`(#E2E5EA)와 같은 계열로 한 단계 진하게 근사했다.
  static const Color borderStrong = Color(0xFFC9CDD6);

  static const Color success = Color(0xFF1E8F5F);
  static const Color warning = Color(0xFFB7791F);
  static const Color error = Color(0xFFC6362E);

  /// SOS 전용 — `error`(#C6362E)와 분리된 색. WCAG AA 대비 조정된 값
  /// (`ui-prototype/css/tokens.css` `--emergency`).
  static const Color emergency = Color(0xFFB84D56);

  /// Senior/Easy Mode 따뜻함 accent(온보딩 컨페티 등) — `--warm-accent`.
  static const Color warmAccent = Color(0xFFE2714B);

  /// Easy Mode 전용 배경(민트/크림) — `--easy-surface`/`--easy-surface-cream`.
  static const Color easySurface = Color(0xFFE9F3EE);
  static const Color easySurfaceCream = Color(0xFFFBF7EC);

  /// Tonal(soft) 배경 — 배지/tonal 버튼/선택 카드가 각자
  /// `color.withValues(alpha: ...)`를 계산하던 것을 토큰화한 것. 항상 이
  /// 값들만 쓰고 위젯에서 alpha를 직접 계산하지 않는다.
  static const Color primarySoft = Color(0xFFEAF0FE);
  static const Color successSoft = Color(0xFFE6F5EC);
  static const Color warningSoft = Color(0xFFFBF1DE);
  static const Color errorSoft = Color(0xFFFBEAE8);
  static const Color emergencySoft = Color(0xFFFAEDEE);

  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
}
