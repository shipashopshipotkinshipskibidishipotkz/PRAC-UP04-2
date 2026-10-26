import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Библиотечная система')),
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
            ],
          ),
        ),
      ),
    );
  }
}