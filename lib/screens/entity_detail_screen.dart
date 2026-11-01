import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/api_exceptions.dart';
import '../core/entity_fields.dart';
import '../models/book.dart';
import '../models/entity_kind.dart';
import '../models/library_entity.dart';
import '../models/page_result.dart';
import '../repositories/library_repository.dart';
import '../widgets/entity_actions.dart';
import '../widgets/api_connection_button.dart';
import '../widgets/loan_dialog.dart';
import '../widgets/pagination_controls.dart';
import '../widgets/states.dart';

class EntityDetailScreen extends StatefulWidget {
  final EntityKind kind;
  final int id;
  const EntityDetailScreen({super.key, required this.kind, required this.id});
  @override
  State<EntityDetailScreen> createState() => _EntityDetailScreenState();
}

class _EntityDetailScreenState extends State<EntityDetailScreen> {
  late final LibraryRepository _repository;
  LibraryEntity? _row;
  PageResult<LibraryEntity> _related = PageResult.empty();
  bool _loading = true;
  String? _error;
  int _generation = 0;
  int _page = 1;
  int _size = 10;
  bool get _hasRelated => const [
    EntityKind.authors,
    EntityKind.genres,
    EntityKind.publishers,
  ].contains(widget.kind);
  @override
  void initState() {
    super.initState();
    _repository = context.read<LibraryRepository>();
    _repository.addListener(_changed);
    _load();
  }

  void _changed() {
    if (mounted) _load();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final values = await Future.wait<Object?>([
        _repository.findById(widget.kind, widget.id),
        _repository.loadReferences().then((_) => null),
        if (_hasRelated)
          _repository.relatedBooks(widget.kind, widget.id, _page, size: _size),
      ]);
      if (!mounted || generation != _generation) return;
      setState(() {
        _row = values[0] as LibraryEntity;
        if (_hasRelated) _related = values[2] as PageResult<LibraryEntity>;
        _loading = false;
      });
    } catch (error) {
      if (mounted && generation == _generation) {
        setState(() {
          _error =
              error is ApiException
                  ? error.message
                  : 'Не удалось загрузить карточку.';
          _loading = false;
        });
      }
    }
  }

  @override
  void didUpdateWidget(covariant EntityDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kind != widget.kind || oldWidget.id != widget.id) {
      _page = 1;
      _load();
    }
  }

  @override
  void dispose() {
    _repository.removeListener(_changed);
    _generation++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repository = _repository;
    final kind = widget.kind;
    final id = widget.id;
    final row = _row;
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
        actions: const [ApiConnectionButton()],
      ),
      body:
          _loading
              ? const LoadingState()
              : _error != null
              ? Padding(
                padding: const EdgeInsets.all(24),
                child: ErrorState(message: _error!, onRetry: _load),
              )
              : row == null
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
                          if (!row.isDeleted)
                            FilledButton.icon(
                              icon: const Icon(Icons.book_outlined),
                              label: const Text('Оформить выдачу'),
                              onPressed: () async {
                                final created = await showDialog<bool>(
                                  context: context,
                                  builder:
                                      (_) => LoanDialog(
                                        repository: repository,
                                        book: row,
                                      ),
                                );
                                if (created == true && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Выдача оформлена'),
                                    ),
                                  );
                                }
                              },
                            ),
                        ],
                        if (_hasRelated) ...[
                          const Divider(height: 32),
                          Text(
                            'Связанные книги (${_related.total})',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          for (final book in _related.items)
                            TextButton(
                              onPressed: () => context.go('/books/${book.id}'),
                              child: Text(EntityKind.books.titleOf(book)),
                            ),
                          if (_related.total > 0)
                            PaginationControls(
                              pageResult: _related,
                              onPageChanged: (page) {
                                _page = page;
                                _load();
                              },
                              onSizeChanged: (size) {
                                _size = size;
                                _page = 1;
                                _load();
                              },
                            ),
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
