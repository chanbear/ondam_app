import 'package:flutter/material.dart';

/// Typography tokens — use instead of hardcoded TextStyle values.
///
/// `ui-prototype/css/tokens.css` 6-role scale (2026-08-30, 사용자 승인) —
/// supersedes the previous "Modern Care" 7-role sizes. Still shared as-is
/// between Senior and Guardian: every widget in this package reads these as
/// static consts rather than through `Theme.of(context).textTheme`, so a
/// per-app profile (Guardian 1px 축소) would require rewriting ~17 widget
/// call sites — tracked as a follow-up, not done here.
abstract final class AppTextStyles {
  /// `--fs-display`.
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );

  /// `--fs-h1`.
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  /// `--fs-title`.
  static const TextStyle titleMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  /// `--fs-body`.
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  /// `--fs-body-sm`.
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  /// ui-prototype에는 직접 대응하는 role이 없다 — `.field label`(13px/600)
  /// 등 소형 semibold 라벨용으로 그대로 유지한다.
  static const TextStyle labelSmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  /// `--fs-caption`. 최소 단계 — 대문자 라벨(예: 섹션 kicker)용. `TextStyle`은
  /// text-transform이 없으므로 대문자 변환은 호출부에서
  /// `.toUpperCase()`로 처리한다.
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );
}
