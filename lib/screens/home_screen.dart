import '../widgets/responsive_grid.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/permissions.dart';
import '../state/auth_notifier.dart';
import '../widgets/api_connection_button.dart';
import '../widgets/workspace_scaffold.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final links = <(IconData, String, String, String)>[
      (
        Icons.menu_book_outlined,
        'Каталог книг',
        'Поиск книг, авторов, жанров и издательств',
        '/books',
      ),
      if (auth.can(Permission.ownLoans))
        (
          Icons.bookmark_outline,
          'Мои выдачи',
          'Ваши книги, сроки возврата и продление',
          '/my-loans',
        ),
      if (auth.can(Permission.librarianDesk))
        (
          Icons.desk_outlined,
          'Рабочее место',
          'Оформление выдач, возвраты и читательские билеты',
          '/desk',
        ),
      if (auth.can(Permission.manageLoans))
        (
          Icons.library_books_outlined,
          'Выдачи и возвраты',
          'Все выдачи библиотеки и оформление возврата',
          '/loans',
        ),
      if (auth.can(Permission.readers))
        (
          Icons.badge_outlined,
          'Читатели',
          'Учёт читателей и читательских билетов',
          '/readers',
        ),
      if (auth.can(Permission.users))
        (
          Icons.manage_accounts_outlined,
          'Пользователи и роли',
          'Управление доступом к библиотеке',
          '/admin/users',
        ),
      if (auth.can(Permission.statistics))
        (
          Icons.bar_chart,
          'Статистика',
          'Фонд библиотеки и состояние выдач',
          '/admin/statistics',
        ),
    ];
    return WorkspaceScaffold(
      location: '/',

      appBar: AppBar(
        title: const Text('Библиотечная система'),
        actions: const [ApiConnectionButton()],
      ),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Здравствуйте, ${auth.user?.fullName ?? ''}',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text('Ваша роль: ${auth.user?.role.label ?? ''}'),
          const SizedBox(height: 24),
          ResponsiveGrid(
            children: [
              for (final link in links)
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Icon(link.$1),
                    title: Text(link.$2),
                    subtitle: Text(link.$3),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go(link.$4),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
