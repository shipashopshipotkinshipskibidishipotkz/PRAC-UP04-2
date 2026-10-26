import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/breakpoints.dart';
import '../models/author.dart';
import '../models/author_query.dart';
import '../models/seed_data.dart';
import '../state/author_list_notifier.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/author_card.dart';
import '../widgets/entity_table.dart';
import '../widgets/filter_panel.dart';
import '../widgets/pagination_controls.dart';
import '../widgets/states.dart';

class AuthorListScreen extends StatefulWidget {
  const AuthorListScreen({super.key});

  @override
  State<AuthorListScreen> createState() => _AuthorListScreenState();
}

class _AuthorListScreenState extends State<AuthorListScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uri = GoRouterState.of(context).uri;
      final initialQuery = AuthorQuery.fromQueryParams(uri.queryParameters);
      if (initialQuery.search.isNotEmpty ||
          initialQuery.country != null ||
          initialQuery.page > 1) {
        _searchController.text = initialQuery.search;
        context.read<AuthorListNotifier>().applyQuery(initialQuery);
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
      _applyQuery(context.read<AuthorListNotifier>().query.copyWith(search: value));
    });
  }

  Future<void> _applyQuery(AuthorQuery next) async {
    final notifier = context.read<AuthorListNotifier>();
    await notifier.applyQuery(next);
    final uri = Uri(path: '/authors', queryParameters: next.toQueryParams());
    if (!_isInitialLoad) {
      context.go(uri.toString());
    }
  }

  void _resetFilters() {
    _searchController.clear();
    _applyQuery(const AuthorQuery());
  }

  Future<void> _confirmDeleteSelected() async {
    final notifier = context.read<AuthorListNotifier>();
    final count = notifier.selected.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить выбранных?'),
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
    final notifier = context.watch<AuthorListNotifier>();
    final size = screenSizeOf(context);

    return AppScaffold(
      selectedIndex: 1,
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
                labelText: 'Поиск по фамилии или стране',
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
                child: DropdownButtonFormField<String?>(
                  isDense: true,
                  isExpanded: true,
                  value: notifier.query.country,
                  decoration: const InputDecoration(
                    labelText: 'Страна',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Все страны')),
                    ...seedAuthors.map((a) => a.country).toSet().map((c) => DropdownMenuItem(value: c, child: Text(c))),
                  ],
                  onChanged: (v) {
                    _applyQuery(notifier.query.copyWith(country: v));
                  },
                ),
              ),
              SizedBox(
                width: 100,
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Год рожд. от',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    final year = int.tryParse(v);
                    _applyQuery(notifier.query.copyWith(birthYearFrom: year));
                  },
                ),
              ),
              SizedBox(
                width: 100,
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Год рожд. до',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    final year = int.tryParse(v);
                    _applyQuery(notifier.query.copyWith(birthYearTo: year));
                  },
                ),
              ),
            ],
            toggleDeleted: SwitchListTile(
              title: const Text('Показать удалённых'),
              value: notifier.query.includeDeleted,
              onChanged: (v) {
                _applyQuery(notifier.query.copyWith(includeDeleted: v));
              },
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            onApply: () {},
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
                    label: const Text('Удалить выбранных'),
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
              child: PaginationControls<Author>(
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

  Widget _buildContent(BuildContext context, AuthorListNotifier notifier, ScreenSize size) {
    return switch (notifier.status) {
      LoadStatus.idle || LoadStatus.loading => const LoadingState(),
      LoadStatus.error => ErrorState(
          message: notifier.error ?? 'Неизвестная ошибка',
          onRetry: () => notifier.load(),
        ),
      LoadStatus.success when notifier.result.items.isEmpty =>
        const EmptyState(message: 'Авторы не найдены'),
      LoadStatus.success => _buildList(context, notifier, size),
    };
  }

  Widget _buildList(BuildContext context, AuthorListNotifier notifier, ScreenSize size) {
    if (size == ScreenSize.compact) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifier.result.items.length,
        itemBuilder: (context, index) {
          final author = notifier.result.items[index];
          return AuthorCard(
            author: author,
            onTap: () => context.go('/authors/${author.id}'),
            onDelete: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Удалить автора?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Удалить')),
                  ],
                ),
              );
              if (confirmed == true) notifier.softDelete(author.id);
            },
            onRestore: author.isDeleted ? () => notifier.restore(author.id) : null,
          );
        },
      );
    }

    return EntityTable<Author>(
      columns: [
        TableColumnSpec<Author>(label: 'Фамилия', sortField: 'lastName', build: (a) => Text(a.lastName)),
        TableColumnSpec<Author>(label: 'Имя', sortField: 'firstName', build: (a) => Text(a.firstName)),
        TableColumnSpec<Author>(label: 'Страна', build: (a) => Text(a.country)),
        TableColumnSpec<Author>(label: 'Год рождения', sortField: 'birthYear', numeric: true, build: (a) => Text('${a.birthYear}')),
      ],
      items: notifier.result.items,
      idOf: (a) => a.id,
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
      actions: (a) => [
        IconButton(icon: const Icon(Icons.visibility), onPressed: () => context.go('/authors/${a.id}')),
        if (a.isDeleted)
          IconButton(icon: const Icon(Icons.restore), onPressed: () => notifier.restore(a.id))
        else
          IconButton(icon: const Icon(Icons.delete), onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Удалить автора?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
                  FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Удалить')),
                ],
              ),
            );
            if (confirmed == true) notifier.softDelete(a.id);
          }),
      ],
    );
  }
}