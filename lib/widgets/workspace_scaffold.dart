import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/permissions.dart';
import '../models/entity_kind.dart';
import '../state/auth_notifier.dart';

class WorkspaceScaffold extends StatelessWidget {
  final String location;
  final Widget child;
  const WorkspaceScaffold({
    super.key,
    required this.location,
    required this.child,
  });
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final destinations = <({String path, String label, IconData icon})>[
      (path: '/', label: 'Главная', icon: Icons.home_outlined),
      for (final kind in EntityKind.values)
        if (kind != EntityKind.readers || auth.can(Permission.readers))
          (
            path: kind.path,
            label: kind.label,
            icon:
                [
                  Icons.menu_book,
                  Icons.person,
                  Icons.category_outlined,
                  Icons.business_outlined,
                  Icons.badge_outlined,
                ][kind.index],
          ),
      if (auth.can(Permission.ownLoans))
        (path: '/my-loans', label: 'Мои выдачи', icon: Icons.bookmark_outline),
      if (auth.can(Permission.librarianDesk))
        (path: '/desk', label: 'Рабочее место', icon: Icons.desk_outlined),
      if (auth.can(Permission.manageLoans))
        (path: '/loans', label: 'Выдачи', icon: Icons.library_books_outlined),
      if (auth.can(Permission.users))
        (
          path: '/admin/users',
          label: 'Пользователи',
          icon: Icons.manage_accounts_outlined,
        ),
      if (auth.can(Permission.statistics))
        (path: '/admin/statistics', label: 'Статистика', icon: Icons.bar_chart),
    ];
    final index = destinations.indexWhere((d) => d.path == location);
    if (MediaQuery.sizeOf(context).width < 700) {
      return Scaffold(
        appBar: AppBar(title: Text(destinations[index < 0 ? 0 : index].label)),
        drawer: Drawer(
          child: SafeArea(
            child: ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Библиотечная система'),
                ),
                for (final d in destinations)
                  ListTile(
                    selected: d.path == location,
                    leading: Icon(d.icon),
                    title: Text(d.label),
                    onTap: () {
                      Navigator.pop(context);
                      context.go(d.path);
                    },
                  ),
              ],
            ),
          ),
        ),
        body: child,
      );
    }
    final extended = MediaQuery.sizeOf(context).width >= 1100;
    return Scaffold(
      body: Row(
        children: [
          SingleChildScrollView(
            child: IntrinsicHeight(
              child: NavigationRail(
                selectedIndex: index < 0 ? 0 : index,
                extended: extended,
                labelType:
                    extended
                        ? NavigationRailLabelType.none
                        : NavigationRailLabelType.all,
                onDestinationSelected: (i) => context.go(destinations[i].path),
                destinations: [
                  for (final d in destinations)
                    NavigationRailDestination(
                      icon: Icon(d.icon),
                      label: Text(d.label),
                    ),
                ],
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
