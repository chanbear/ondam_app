import 'package:flutter/material.dart';

/// Color tokens — background/text/border values match the Phase 42-approved
/// Senior/Guardian HTML prototype palette (`prototype/senior/styles.css`,
/// `prototype/guardian/styles.css`), shared identically by both apps.
/// `primary` was updated to the blue accent (`#1D61E7`) used for CTAs/
/// selected states/toggles in the "온담 최종 디자인" Figma file (초기 설정
/// 화면, node `1:108`) — the file's own `--primary` variable is still green
/// (`#2f6f4e`, unused by any rendered element on that screen), so the
/// visually-applied blue is treated as the actual intended accent.
///
/// NOTE: no `emergency` token yet — technical-decisions.md OPEN QUESTIONS #7
/// (실제 색상값) is still open, so one is not invented here. `secondary` and
/// the `*Dark` pair aren't covered by either reference (light-mode only, no
/// secondary-accent concept) and are left unchanged pending a follow-up
/// decision.
abstract final class AppColors {
  static const Color primary = Color(0xFF1D61E7);
  static const Color secondary = Color(0xFF00BFA5);

  static const Color background = Color(0xFFF6F4EF);
  static const Color surface = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF1E1B16);
  static const Color textSecondary = Color(0xFF635C4F);
  static const Color textDisabled = Color(0xFFBDBDBD);

  static const Color border = Color(0xFFDFD9CC);
  static const Color divider = Color(0xFFDFD9CC);

  static const Color success = Color(0xFF1E6B45);
  static const Color warning = Color(0xFF8A5A00);
  static const Color error = Color(0xFFB3261E);

  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
}
