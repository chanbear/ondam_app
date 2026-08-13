import 'package:flutter/material.dart';

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
/// come from here, tab items are injected by each app.
class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<AppBottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      destinations: [
        for (final item in items)
          NavigationDestination(icon: _iconWithBadge(item), label: item.label),
      ],
    );
  }

  Widget _iconWithBadge(AppBottomNavItem item) {
    final icon = Icon(item.icon);
    final badgeCount = item.badgeCount;
    if (badgeCount == null || badgeCount <= 0) return icon;
    return Badge(label: Text('$badgeCount'), child: icon);
  }
}
