import 'package:flutter/material.dart';

/// Icon-only button that forces a semantic label — icons never carry meaning
/// alone (ui-design.md accessibility rule), so `semanticLabel` is required,
/// not optional, to make it impossible to forget.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    this.onPressed,
    this.size = 24,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: IconButton(
        icon: Icon(icon, size: size),
        onPressed: onPressed,
        tooltip: semanticLabel,
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      ),
    );
  }
}
