import 'package:flutter/material.dart';

/// Color tokens — values match the Phase 42-approved Senior/Guardian HTML
/// prototype palette (`prototype/senior/styles.css`, `prototype/guardian/styles.css`),
/// which is shared identically by both apps.
///
/// NOTE: no `emergency` token yet — technical-decisions.md OPEN QUESTIONS #7
/// (실제 색상값) is still open, so one is not invented here. `secondary` and
/// the `*Dark` pair aren't covered by the HTML prototype (light-mode only,
/// no secondary-accent concept) and are left unchanged from their prior
/// placeholder values pending a follow-up decision.
abstract final class AppColors {
  static const Color primary = Color(0xFF2F6F4E);
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
