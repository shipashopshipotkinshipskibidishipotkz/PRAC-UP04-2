import 'package:flutter/material.dart';
import '../models/book.dart';
import '../models/seed_data.dart';

class BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;

  const BookCard({
    super.key,
    required this.book,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final authors = book.authorIds
        .map(
          (id) =>
              seedAuthors
                  .firstWhere(
                    (a) => a.id == id,
                    orElse: () => seedAuthors.first,
                  )
                  .fullName,
        )
        .join(', ');
    final genre = book.genreIds
        .map((id) => genres[id] ?? '')
        .where((g) => g.isNotEmpty)
        .join(', ');
    final publisher = publishers[book.publisherId] ?? '';

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      book.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (book.isDeleted)
                    const Chip(
                      label: Text('Удалена'),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Автор: $authors'),
              Text('Жанр: $genre'),
              Text('Издательство: $publisher'),
              Text('Год: ${book.year}'),
              Text('Страниц: ${book.pages}'),
              Text('Доступно: ${book.copiesAvailable} / ${book.copiesTotal}'),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (onEdit != null)
                    IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
                  if (book.isDeleted && onRestore != null)
                    IconButton(
                      icon: const Icon(Icons.restore),
                      onPressed: onRestore,
                    ),
                  if (!book.isDeleted && onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: onDelete,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
