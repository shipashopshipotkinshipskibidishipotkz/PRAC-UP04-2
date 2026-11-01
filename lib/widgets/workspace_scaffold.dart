import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/permissions.dart';
import '../models/entity_kind.dart';
import '../state/auth_notifier.dart';
import '../core/breakpoints.dart';

class WorkspaceScaffold extends StatelessWidget {
  final String location;
  final Widget child;
  final PreferredSizeWidget? appBar;
  const WorkspaceScaffold({
    super.key,
    required this.location,
    required this.child,
    this.appBar,
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
    final screen = screenSizeOf(context);
    Widget content() => Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1440),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
    if (screen == ScreenSize.compact) {
      final primaryPaths = [
        '/',
        '/books',
        auth.can(Permission.ownLoans)
            ? '/my-loans'
            : auth.can(Permission.users)
            ? '/admin/users'
            : auth.can(Permission.manageLoans)
            ? '/loans'
            : '/authors',
      ];
      final primary = [
        for (final path in primaryPaths)
          destinations.firstWhere((d) => d.path == path),
      ];
      final selected = primary.indexWhere((d) => d.path == location);
      return Scaffold(
        appBar: appBar,
        body: content(),
        bottomNavigationBar: NavigationBar(
          selectedIndex: selected < 0 ? 3 : selected,
          onDestinationSelected: (i) {
            if (i < 3) {
              context.go(primary[i].path);
              return;
            }
            showModalBottomSheet<void>(
              context: context,
              useSafeArea: true,
              isScrollControlled: true,
              constraints: const BoxConstraints(maxWidth: 560),
              builder:
                  (sheetContext) => ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * .75,
                    ),
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('Разделы библиотеки'),
                        ),
                        for (final d in destinations)
                          ListTile(
                            selected: d.path == location,
                            leading: Icon(d.icon),
                            title: Text(d.label),
                            onTap: () {
                              Navigator.pop(sheetContext);
                              context.go(d.path);
                            },
                          ),
                      ],
                    ),
                  ),
            );
          },
          destinations: [
            for (final d in primary)
              NavigationDestination(icon: Icon(d.icon), label: d.label),
            const NavigationDestination(
              icon: Icon(Icons.more_horiz),
              label: 'Ещё',
            ),
          ],
        ),
      );
    }
    final extended = screen == ScreenSize.expanded;
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
                        : NavigationRailLabelType.none,
                onDestinationSelected: (i) => context.go(destinations[i].path),
                destinations: [
                  for (final d in destinations)
                    NavigationRailDestination(
                      icon: Tooltip(message: d.label, child: Icon(d.icon)),
                      label: Text(d.label),
                    ),
                ],
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child:
                appBar == null
                    ? content()
                    : Scaffold(appBar: appBar, body: content()),
          ),
        ],
      ),
    );
  }
}
