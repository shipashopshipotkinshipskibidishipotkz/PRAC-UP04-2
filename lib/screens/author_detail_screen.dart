import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AuthorDetailScreen extends StatelessWidget {
  final int authorId;

  const AuthorDetailScreen({super.key, required this.authorId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Карточка автора')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ID автора: $authorId', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                const Text('(Здесь будет полная карточка автора)'),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.go('/authors'),
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