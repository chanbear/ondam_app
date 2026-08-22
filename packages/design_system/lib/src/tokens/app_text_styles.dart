import 'package:flutter/material.dart';

/// Typography tokens — use instead of hardcoded TextStyle values.
///
/// Sizes match the Phase 42-approved Senior HTML prototype scale
/// (base/lg/xl/xxl = 17/20/25/32). Guardian's prototype scale is one step
/// smaller (16/19/24/30) but there is no per-app profile here yet: every
/// widget in this package reads these as static consts rather than through
/// `Theme.of(context).textTheme`, so a dual-scale system would require
/// rewriting ~17 widget call sites (out of scope for Phase 43's token
/// extraction). Senior's scale was kept as the single shared baseline since
/// larger-by-default is the safer direction for the accessibility-critical
/// app; Guardian renders 1-2px larger than its own prototype spec until that
/// refactor happens.
abstract final class AppTextStyles {
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 1.25,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 25,
    fontWeight: FontWeight.bold,
    height: 1.3,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );
}
