import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BookDetailScreen extends StatelessWidget {
  final int bookId;

  const BookDetailScreen({super.key, required this.bookId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Карточка книги'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ID книги: $bookId', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                const Text('(Здесь будет полная карточка книги с формой редактирования)'),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.go('/books'),
                  child: const Text('Назад к списку'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}