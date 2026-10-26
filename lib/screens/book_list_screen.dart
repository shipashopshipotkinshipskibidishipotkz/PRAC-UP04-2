import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/breakpoints.dart';
import '../models/book.dart';
import '../models/book_query.dart';
import '../models/seed_data.dart';
import '../state/book_list_notifier.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/book_card.dart';
import '../widgets/entity_table.dart';
import '../widgets/filter_panel.dart';
import '../widgets/pagination_controls.dart';
import '../widgets/states.dart';

class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uri = GoRouterState.of(context).uri;
      final initialQuery = BookQuery.fromQueryParams(uri.queryParameters);
      if (initialQuery.search.isNotEmpty ||
          initialQuery.genreId != null ||
          initialQuery.page > 1) {
        _searchController.text = initialQuery.search;
        context.read<BookListNotifier>().applyQuery(initialQuery);
      }
      _isInitialLoad = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _applyQuery(context.read<BookListNotifier>().query.copyWith(search: value));
    });
  }

  Future<void> _applyQuery(BookQuery next) async {
    final notifier = context.read<BookListNotifier>();
    await notifier.applyQuery(next);
    final uri = Uri(path: '/books', queryParameters: next.toQueryParams());
    if (!_isInitialLoad) {
      context.go(uri.toString());
    }
  }

  void _applyFilters() {
    final notifier = context.read<BookListNotifier>();
    _applyQuery(notifier.query);
  }

  void _resetFilters() {
    _searchController.clear();
    _applyQuery(const BookQuery());
  }

  Future<void> _confirmDelete(BuildContext context, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить книгу?'),
        content: const Text('Книга будет удалена логически. Её можно будет восстановить.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Удалить')),
        ],
      ),
    );
    if (confirmed == true) {
      context.read<BookListNotifier>().softDelete(id);
    }
  }

  Future<void> _confirmDeleteSelected() async {
    final notifier = context.read<BookListNotifier>();
    final count = notifier.selected.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить выбранные?'),
        content: Text('Будет удалено записей: $count'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Удалить')),
        ],
      ),
    );
    if (confirmed == true) {
      notifier.deleteSelected();
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<BookListNotifier>();
    final size = screenSizeOf(context);

    return AppScaffold(
      selectedIndex: 0,
      onDestinationSelected: (i) {
        if (i == 0) context.go('/books');
        if (i == 1) context.go('/authors');
      },
      child: Column(
        children: [
          FilterPanel(
            searchField: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Поиск по названию или ISBN',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: _onSearchChanged,
            ),
            filters: [
              SizedBox(
                width: 160,
                child: DropdownButtonFormField<int?>(
                  isDense: true,
                  isExpanded: true,
                  value: notifier.query.genreId,
                  decoration: const InputDecoration(
                    labelText: 'Жанр',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Все жанры')),
                    ...genres.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))),
                  ],
                  onChanged: (v) {
                    _applyQuery(notifier.query.copyWith(genreId: v));
                  },
                ),
              ),
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<int?>(
                  isDense: true,
                  isExpanded: true,
                  value: notifier.query.publisherId,
                  decoration: const InputDecoration(
                    labelText: 'Издательство',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Все издательства')),
                    ...publishers.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))),
                  ],
                  onChanged: (v) {
                    _applyQuery(notifier.query.copyWith(publisherId: v));
                  },
                ),
              ),
              SizedBox(
                width: 100,
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Год от',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    final year = int.tryParse(v);
                    _applyQuery(notifier.query.copyWith(yearFrom: year));
                  },
                ),
              ),
              SizedBox(
                width: 100,
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Год до',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    final year = int.tryParse(v);
                    _applyQuery(notifier.query.copyWith(yearTo: year));
                  },
                ),
              ),
            ],
            toggleDeleted: SwitchListTile(
              title: const Text('Показать удалённые'),
              value: notifier.query.includeDeleted,
              onChanged: (v) {
                _applyQuery(notifier.query.copyWith(includeDeleted: v));
              },
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            onApply: _applyFilters,
            onReset: _resetFilters,
          ),
          if (notifier.hasSelection)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text('Выбрано: ${notifier.selected.length}'),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: _confirmDeleteSelected,
                    icon: const Icon(Icons.delete),
                    label: const Text('Удалить выбранные'),
                  ),
                  TextButton(onPressed: notifier.clearSelection, child: const Text('Снять выделение')),
                ],
              ),
            ),
          Expanded(
            child: _buildContent(context, notifier, size),
          ),
          if (notifier.status == LoadStatus.success && notifier.result.total > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: PaginationControls<Book>(
                pageResult: notifier.result,
                onPageChanged: (page) {
                  _applyQuery(notifier.query.copyWith(page: page));
                },
                onSizeChanged: (size) {
                  _applyQuery(notifier.query.copyWith(size: size, page: 1));
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, BookListNotifier notifier, ScreenSize size) {
    return switch (notifier.status) {
      LoadStatus.idle || LoadStatus.loading => const LoadingState(),
      LoadStatus.error => ErrorState(
          message: notifier.error ?? 'Неизвестная ошибка',
          onRetry: () => notifier.load(),
        ),
      LoadStatus.success when notifier.result.items.isEmpty =>
        const EmptyState(message: 'Книги не найдены'),
      LoadStatus.success => _buildList(context, notifier, size),
    };
  }

  Widget _buildList(BuildContext context, BookListNotifier notifier, ScreenSize size) {
    if (size == ScreenSize.compact) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifier.result.items.length,
        itemBuilder: (context, index) {
          final book = notifier.result.items[index];
          return BookCard(
            book: book,
            onTap: () => context.go('/books/${book.id}'),
            onDelete: () => _confirmDelete(context, book.id),
            onRestore: book.isDeleted ? () => notifier.restore(book.id) : null,
          );
        },
      );
    }

    return EntityTable<Book>(
      columns: [
        TableColumnSpec<Book>(label: 'Название', sortField: 'title', build: (b) => Text(b.title)),
        TableColumnSpec<Book>(label: 'Год', sortField: 'year', numeric: true, build: (b) => Text('${b.year}')),
        TableColumnSpec<Book>(label: 'Страниц', sortField: 'pages', numeric: true, build: (b) => Text('${b.pages}')),
        TableColumnSpec<Book>(
          label: 'Издательство',
          build: (b) => Text(publishers[b.publisherId] ?? ''),
        ),
      ],
      items: notifier.result.items,
      idOf: (b) => b.id,
      selected: notifier.selected,
      onToggleSelect: notifier.toggleSelection,
      sortField: notifier.query.sortField,
      sortAscending: notifier.query.sortAscending,
      onSort: (field) {
        _applyQuery(notifier.query.copyWith(
          sortField: field,
          sortAscending: field == notifier.query.sortField ? !notifier.query.sortAscending : true,
        ));
      },
      actions: (b) => [
        IconButton(icon: const Icon(Icons.visibility), onPressed: () => context.go('/books/${b.id}')),
        if (b.isDeleted)
          IconButton(icon: const Icon(Icons.restore), onPressed: () => notifier.restore(b.id))
        else
          IconButton(icon: const Icon(Icons.delete), onPressed: () => _confirmDelete(context, b.id)),
      ],
    );
  }
}