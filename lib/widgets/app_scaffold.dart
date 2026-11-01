import 'package:flutter/material.dart';
import '../core/breakpoints.dart';

class AppScaffold extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;

  const AppScaffold({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.child,
  });

  static const _destinations = [
    (icon: Icons.menu_book, label: 'Книги'),
    (icon: Icons.person, label: 'Авторы'),
    (icon: Icons.category_outlined, label: 'Жанры'),
    (icon: Icons.business_outlined, label: 'Издательства'),
    (icon: Icons.badge_outlined, label: 'Читатели'),
  ];

  @override
  Widget build(BuildContext context) {
    final size = screenSizeOf(context);

    if (size == ScreenSize.compact) {
      return Scaffold(
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          destinations: [
            for (final d in _destinations)
              NavigationDestination(
                icon: Icon(d.icon),
                label: d.label == 'Издательства' ? 'Издатели' : d.label,
              ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            extended: size == ScreenSize.expanded,
            labelType:
                size == ScreenSize.expanded
                    ? NavigationRailLabelType.none
                    : NavigationRailLabelType.all,
            destinations: [
              for (final d in _destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  label: Text(d.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
