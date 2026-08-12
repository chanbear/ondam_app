import 'package:flutter/material.dart';

/// Placeholder color tokens — replace with real values from the Figma design
/// system. See ui-spec.md "토큰 매핑" for how these compare to the measured
/// values from the reference web app.
///
/// NOTE: no `emergency` token yet — technical-decisions.md OPEN QUESTIONS #7
/// (실제 색상값) is still open, so one is not invented here.
abstract final class AppColors {
  static const Color primary = Color(0xFF3D5AFE);
  static const Color secondary = Color(0xFF00BFA5);

  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF5F5F7);

  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6E6E73);
  static const Color textDisabled = Color(0xFFBDBDBD);

  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFEEEEEE);

  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);
  static const Color error = Color(0xFFD32F2F);

  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
}
