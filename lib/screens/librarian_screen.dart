import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/api_connection_button.dart';
import '../widgets/workspace_scaffold.dart';

class LibrarianScreen extends StatelessWidget {
  const LibrarianScreen({super.key});
  @override
  Widget build(BuildContext context) => WorkspaceScaffold(
    location: '/desk',

    appBar: AppBar(
      title: const Text('Рабочее место библиотекаря'),
      actions: const [ApiConnectionButton()],
    ),
    child: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Обслуживание читателей',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        const Text(
          'Оформите новую выдачу из карточки книги или зарегистрируйте возврат.',
        ),
        const SizedBox(height: 24),
        for (final item in [
          (Icons.menu_book_outlined, 'Оформить выдачу', '/books'),
          (Icons.assignment_turned_in_outlined, 'Выдачи и возвраты', '/loans'),
          (Icons.badge_outlined, 'Читатели и билеты', '/readers'),
        ])
          Card(
            child: ListTile(
              leading: Icon(item.$1),
              title: Text(item.$2),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go(item.$3),
            ),
          ),
      ],
    ),
  );
}
