import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/api_connection_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Библиотечная система'), actions: const [ApiConnectionButton()]),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: () => context.go('/books'),
                icon: const Icon(Icons.menu_book),
                label: const Text('Каталог книг'),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => context.go('/authors'),
                icon: const Icon(Icons.person),
                label: const Text('Авторы'),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => context.go('/genres'),
                icon: const Icon(Icons.category_outlined),
                label: const Text('Жанры'),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => context.go('/publishers'),
                icon: const Icon(Icons.business_outlined),
                label: const Text('Издательства'),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => context.go('/readers'),
                icon: const Icon(Icons.badge_outlined),
                label: const Text('Читатели'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
