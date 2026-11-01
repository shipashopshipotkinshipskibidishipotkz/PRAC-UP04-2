import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/entity_fields.dart';
import '../models/book.dart';
import '../models/entity_kind.dart';
import '../repositories/persistent_library_repository.dart';
import '../widgets/entity_actions.dart';

class EntityDetailScreen extends StatelessWidget {
  final EntityKind kind;
  final int id;
  const EntityDetailScreen({super.key, required this.kind, required this.id});
  @override
  Widget build(BuildContext context) {
    final repository = context.watch<PersistentLibraryRepository>();
    final row = repository.byId(kind, id);
    Widget link(EntityKind target, int id) => TextButton(
      onPressed: () => context.go('${target.path}/$id'),
      child: Text(repository.title(target, id)),
    );
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Назад к списку',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(kind.path),
        ),
        title: Text('Карточка: ${kind.singular.toLowerCase()}'),
      ),
      body:
          row == null
              ? const Center(child: Text('Запись не найдена'))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          kind.titleOf(row),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        Text('ID: ${row.id}'),
                        if (row.isDeleted) const Chip(label: Text('В корзине')),
                        const SizedBox(height: 24),
                        for (final field in fieldsFor(kind)) ...[
                          if (field.name == 'card.number')
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Text(
                                'Читательский билет · связь 1:1',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: SelectableText(
                              '${field.label}: ${fieldText(row.toJson(), field.name).isEmpty ? '—' : fieldText(row.toJson(), field.name)}',
                            ),
                          ),
                        ],
                        if (row is Book) ...[
                          const Divider(height: 32),
                          const Text('Издательство'),
                          link(EntityKind.publishers, row.publisherId),
                          const Text('Авторы'),
                          Wrap(
                            children: [
                              for (final id in row.authorIds)
                                link(EntityKind.authors, id),
                            ],
                          ),
                          const Text('Жанры'),
                          Wrap(
                            children: [
                              for (final id in row.genreIds)
                                link(EntityKind.genres, id),
                            ],
                          ),
                        ],
                        if (const [
                          EntityKind.authors,
                          EntityKind.genres,
                          EntityKind.publishers,
                        ].contains(kind)) ...[
                          const Divider(height: 32),
                          Text(
                            'Связанные книги (${repository.linkedBookCount(kind, id)})',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          for (final book in repository
                              .all(EntityKind.books, includeDeleted: true)
                              .cast<Book>()
                              .where(
                                (book) => switch (kind) {
                                  EntityKind.authors => book.authorIds.contains(
                                    id,
                                  ),
                                  EntityKind.genres => book.genreIds.contains(
                                    id,
                                  ),
                                  _ => book.publisherId == id,
                                },
                              ))
                            link(EntityKind.books, book.id),
                        ],
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            if (!row.isDeleted)
                              FilledButton.icon(
                                onPressed:
                                    () => context.go('${kind.path}/$id/edit'),
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text('Редактировать'),
                              ),
                            if (row.isDeleted)
                              FilledButton.icon(
                                onPressed:
                                    () => EntityActions.restore(
                                      context,
                                      repository,
                                      kind,
                                      id,
                                    ),
                                icon: const Icon(Icons.restore),
                                label: const Text('Восстановить'),
                              ),
                            if (!row.isDeleted)
                              OutlinedButton.icon(
                                onPressed:
                                    () => EntityActions.delete(
                                      context,
                                      repository,
                                      kind,
                                      [id],
                                    ),
                                icon: const Icon(Icons.delete_outline),
                                label: const Text('В корзину'),
                              ),
                            OutlinedButton.icon(
                              onPressed:
                                  () => EntityActions.delete(
                                    context,
                                    repository,
                                    kind,
                                    [id],
                                    hard: true,
                                  ),
                              icon: const Icon(Icons.delete_forever_outlined),
                              label: const Text('Удалить навсегда'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }
}
