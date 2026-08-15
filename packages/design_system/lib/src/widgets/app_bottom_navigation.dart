import 'package:flutter/material.dart';

import '../tokens/app_easy_mode.dart';
import '../tokens/app_text_styles.dart';

/// One item in [AppBottomNavigation]. Tab composition (which items, how
/// many) is decided per app — Senior and Guardian have different tab sets
/// (ui-information-architecture.md), only the shell/styling is shared.
class AppBottomNavItem {
  const AppBottomNavItem({
    required this.icon,
    required this.label,
    this.badgeCount,
  });

  final IconData icon;
  final String label;
  final int? badgeCount;
}

/// Shared bottom tab bar shell — active/inactive styling and badge counts
/// come from here, tab items are injected by each app. [large] enlarges
/// icons/labels for Senior App Easy Mode (OPEN QUESTIONS 8, DECIDED: style
/// only — tab count/composition never changes) and is unused by Guardian.
class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.large = false,
  });

  final List<AppBottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final iconSize = large ? 24 * AppEasyMode.navIconScale : 24.0;
    final labelStyle = large
        ? AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)
        : AppTextStyles.labelSmall;

    return NavigationBarTheme(
      data: NavigationBarThemeData(
        labelTextStyle: WidgetStatePropertyAll(labelStyle),
      ),
      child: NavigationBar(
        height: large ? AppEasyMode.navBarHeight : null,
        selectedIndex: currentIndex,
        onDestinationSelected: onTap,
        destinations: [
          for (final item in items)
            NavigationDestination(
              icon: _iconWithBadge(item, iconSize),
              label: item.label,
            ),
        ],
      ),
    );
  }

  Widget _iconWithBadge(AppBottomNavItem item, double size) {
    final icon = Icon(item.icon, size: size);
    final badgeCount = item.badgeCount;
    if (badgeCount == null || badgeCount <= 0) return icon;
    return Badge(label: Text('$badgeCount'), child: icon);
  }
}
