import 'package:flutter/material.dart';

import '../tokens/app_touch.dart';

/// Icon-only button that forces a semantic label — icons never carry meaning
/// alone (ui-design.md accessibility rule), so `semanticLabel` is required,
/// not optional, to make it impossible to forget. [touchSize] selects the
/// minimum tap target — [AppTouch.standard] (default) or [AppTouch.easy] for
/// Easy Mode.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    this.onPressed,
    this.size = 24,
    this.touchSize = AppTouch.standard,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final double size;
  final double touchSize;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: IconButton(
        icon: Icon(icon, size: size),
        onPressed: onPressed,
        tooltip: semanticLabel,
        constraints: BoxConstraints(minWidth: touchSize, minHeight: touchSize),
      ),
    );
  }
}
