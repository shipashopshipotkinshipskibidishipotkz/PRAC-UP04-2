import 'package:flutter/material.dart';
import '../models/author.dart';

class AuthorCard extends StatelessWidget {
  final Author author;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;

  const AuthorCard({
    super.key,
    required this.author,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
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
                      author.fullName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (author.isDeleted)
                    const Chip(label: Text('Удалён'), visualDensity: VisualDensity.compact),
                ],
              ),
              const SizedBox(height: 8),
              Text('Страна: ${author.country}'),
              Text('Годы жизни: ${author.birthYear} – ${author.deathYear ?? 'н.в.'}'),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (onEdit != null)
                    IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
                  if (author.isDeleted && onRestore != null)
                    IconButton(icon: const Icon(Icons.restore), onPressed: onRestore),
                  if (!author.isDeleted && onDelete != null)
                    IconButton(icon: const Icon(Icons.delete), onPressed: onDelete),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}