import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/entity_fields.dart';
import '../core/validators.dart';
import '../models/catalog_query.dart';
import '../models/entity_kind.dart';
import '../models/library_entity.dart';
import '../repositories/persistent_library_repository.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/entity_actions.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_controls.dart';

class CatalogListScreen extends StatefulWidget {
  final EntityKind kind;
  final Map<String, String> queryParameters;
  const CatalogListScreen({
    super.key,
    required this.kind,
    this.queryParameters = const {},
  });
  @override
  State<CatalogListScreen> createState() => _CatalogListScreenState();
}

class _CatalogListScreenState extends State<CatalogListScreen> {
  late CatalogQuery _query;
  final _search = TextEditingController();
  final _selected = <int>{};
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _restoreQuery();
  }

  void _restoreQuery() {
    _query = CatalogQuery.fromParams(widget.queryParameters);
    if (_search.text != _query.search) _search.text = _query.search;
  }

  @override
  void didUpdateWidget(covariant CatalogListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kind != widget.kind ||
        !mapEquals(oldWidget.queryParameters, widget.queryParameters)) {
      _debounce?.cancel();
      _restoreQuery();
      _selected.clear();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _apply(CatalogQuery query) {
    _debounce?.cancel();
    setState(() {
      _query = query;
      _selected.clear();
    });
    context.go(
      Uri(path: widget.kind.path, queryParameters: query.toParams()).toString(),
    );
  }

  void _filter(String name, String? value) {
    final filters = {..._query.filters};
    if (value == null || value.isEmpty) {
      filters.remove(name);
    } else {
      filters[name] = value;
    }
    _apply(_query.copyWith(filters: filters));
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<PersistentLibraryRepository>();
    final kind = widget.kind;
    final result = repository.find(kind, _query);
    final columns = switch (kind) {
      EntityKind.books => [
        ('title', 'Название'),
        ('year', 'Год'),
        ('pages', 'Страниц'),
        ('publisherId', 'Издательство'),
      ],
      EntityKind.authors => [
        ('fullName', 'ФИО'),
        ('country', 'Страна'),
        ('birthYear', 'Год рождения'),
      ],
      EntityKind.genres => [('name', 'Жанр'), ('description', 'Описание')],
      EntityKind.publishers => [
        ('name', 'Издательство'),
        ('city', 'Город'),
        ('foundedYear', 'Год основания'),
      ],
      EntityKind.readers => [
        ('fullName', 'ФИО'),
        ('email', 'Почта'),
        ('card.number', 'Билет'),
        ('card.expiresAt', 'Действителен до'),
      ],
    };
    String valueOf(LibraryEntity row, String field) =>
        field == 'publisherId'
            ? repository.title(
              EntityKind.publishers,
              row.toJson()['publisherId'] as int,
            )
            : fieldText(row.toJson(), field);

    List<Widget> actions(LibraryEntity row) => [
      IconButton(
        tooltip: 'Открыть карточку',
        icon: const Icon(Icons.visibility_outlined),
        onPressed: () => context.go('${kind.path}/${row.id}'),
      ),
      if (!row.isDeleted)
        IconButton(
          tooltip: 'Редактировать',
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => context.go('${kind.path}/${row.id}/edit'),
        ),
      if (row.isDeleted)
        IconButton(
          tooltip: 'Восстановить',
          icon: const Icon(Icons.restore),
          onPressed:
              () => EntityActions.restore(context, repository, kind, row.id),
        )
      else
        IconButton(
          tooltip: 'В корзину',
          icon: const Icon(Icons.delete_outline),
          onPressed:
              () => EntityActions.delete(context, repository, kind, [row.id]),
        ),
      IconButton(
        tooltip: 'Удалить навсегда',
        icon: const Icon(Icons.delete_forever_outlined),
        onPressed:
            () => EntityActions.delete(context, repository, kind, [
              row.id,
            ], hard: true),
      ),
    ];

    return AppScaffold(
      selectedIndex: kind.index,
      onDestinationSelected:
          (index) => context.go(EntityKind.values[index].path),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              Text(
                kind.label,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              FilledButton.icon(
                onPressed: () => context.go('${kind.path}/new'),
                icon: const Icon(Icons.add),
                label: const Text('Добавить'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Библиотечная система · каталог'),
          if (repository.storageNotice != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(repository.storageNotice!),
                    TextButton(
                      onPressed: repository.dismissNotice,
                      child: const Text('Понятно'),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _search,
                    decoration: InputDecoration(
                      labelText:
                          kind == EntityKind.books
                              ? 'Поиск по названию или ISBN'
                              : 'Поиск: ${kind.label.toLowerCase()}',
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _debounce?.cancel();
                      _debounce = Timer(const Duration(milliseconds: 300), () {
                        if (mounted) _apply(_query.copyWith(search: value));
                      });
                    },
                    onSubmitted:
                        (value) => _apply(_query.copyWith(search: value)),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ..._filters(repository),
                      SizedBox(
                        width: 220,
                        child: DropdownButtonFormField<String>(
                          key: ValueKey('sort:${_query.sortField}'),
                          value:
                              columns.any((c) => c.$1 == _query.sortField)
                                  ? _query.sortField
                                  : columns.first.$1,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Сортировать по',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            for (final column in columns)
                              DropdownMenuItem(
                                value: column.$1,
                                child: Text(column.$2),
                              ),
                          ],
                          onChanged:
                              (value) =>
                                  _apply(_query.copyWith(sortField: value)),
                        ),
                      ),
                      IconButton(
                        tooltip:
                            _query.ascending ? 'По возрастанию' : 'По убыванию',
                        icon: Icon(
                          _query.ascending
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                        ),
                        onPressed:
                            () => _apply(
                              _query.copyWith(ascending: !_query.ascending),
                            ),
                      ),
                      FilterChip(
                        label: const Text('Показать удалённые'),
                        selected: _query.includeDeleted,
                        onSelected:
                            (value) =>
                                _apply(_query.copyWith(includeDeleted: value)),
                      ),
                      TextButton(
                        onPressed: () {
                          _search.clear();
                          _apply(const CatalogQuery());
                        },
                        child: const Text('Сбросить'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_selected.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('Выбрано: ${_selected.length}'),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await EntityActions.delete(
                        context,
                        repository,
                        kind,
                        _selected,
                      );
                      if (mounted) setState(_selected.clear);
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Удалить выбранные'),
                  ),
                  TextButton(
                    onPressed: () => setState(_selected.clear),
                    child: const Text('Снять выделение'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          if (result.items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Text(
                  'Записи не найдены. Измените фильтры или добавьте запись.',
                ),
              ),
            )
          else if (MediaQuery.sizeOf(context).width < 700)
            ...result.items.map(
              (row) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(kind.titleOf(row)),
                        subtitle:
                            row.isDeleted ? const Text('В корзине') : null,
                        value: _selected.contains(row.id),
                        onChanged:
                            (_) => setState(
                              () =>
                                  _selected.contains(row.id)
                                      ? _selected.remove(row.id)
                                      : _selected.add(row.id),
                            ),
                      ),
                      for (final column in columns.skip(1))
                        Text('${column.$2}: ${valueOf(row, column.$1)}'),
                      Wrap(children: actions(row)),
                    ],
                  ),
                ),
              ),
            )
          else
            EntityTable<LibraryEntity>(
              columns: [
                for (final column in columns)
                  TableColumnSpec(
                    label: column.$2,
                    sortField: column.$1,
                    build:
                        (row) => ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 290),
                          child: Text(
                            '${valueOf(row, column.$1)}${row.isDeleted && column == columns.first ? ' (в корзине)' : ''}',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                  ),
              ],
              items: result.items,
              idOf: (row) => row.id,
              labelOf: kind.titleOf,
              selected: _selected,
              onToggleSelect:
                  (id) => setState(
                    () =>
                        _selected.contains(id)
                            ? _selected.remove(id)
                            : _selected.add(id),
                  ),
              sortField:
                  columns.any((c) => c.$1 == _query.sortField)
                      ? _query.sortField
                      : columns.first.$1,
              sortAscending: _query.ascending,
              onSort:
                  (field) => _apply(
                    _query.copyWith(
                      sortField: field,
                      ascending:
                          field ==
                                  (_query.sortField.isEmpty
                                      ? kind.titleField
                                      : _query.sortField)
                              ? !_query.ascending
                              : true,
                    ),
                  ),
              actions: actions,
            ),
          PaginationControls(
            pageResult: result,
            onPageChanged: (page) => _apply(_query.copyWith(page: page)),
            onSizeChanged: (size) => _apply(_query.copyWith(size: size)),
          ),
        ],
      ),
    );
  }

  List<Widget> _filters(PersistentLibraryRepository repository) {
    Widget dropdown(String name, String label, Map<String, String> options) =>
        SizedBox(
          width: 220,
          child: DropdownButtonFormField<String>(
            key: ValueKey(
              '$name:${_query.filters[name]}:${options.keys.join(",")}',
            ),
            value:
                options.containsKey(_query.filters[name])
                    ? _query.filters[name]
                    : '',
            isExpanded: true,
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(value: '', child: Text('Все')),
              for (final entry in options.entries.where(
                (entry) => entry.key.isNotEmpty,
              ))
                DropdownMenuItem(value: entry.key, child: Text(entry.value)),
            ],
            onChanged: (value) => _filter(name, value),
          ),
        );
    Widget year(String name, String label) => SizedBox(
      width: 150,
      child: TextFormField(
        key: ValueKey('$name:${_query.filters[name]}'),
        initialValue: _query.filters[name] ?? '',
        keyboardType: TextInputType.number,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: InputDecoration(
          labelText: label,
          helperText: 'Enter — применить',
          border: const OutlineInputBorder(),
        ),
        validator: V.integer(min: 1, max: DateTime.now().year, optional: true),
        onFieldSubmitted: (value) {
          if (V.integer(min: 1, max: DateTime.now().year, optional: true)(
                value,
              ) ==
              null) {
            _filter(name, value);
          }
        },
      ),
    );
    return switch (widget.kind) {
      EntityKind.books => [
        dropdown('genreId', 'Жанр', {
          for (final row in repository.all(
            EntityKind.genres,
            includeDeleted: true,
          ))
            '${row.id}': EntityKind.genres.titleOf(row),
        }),
        dropdown('publisherId', 'Издательство', {
          for (final row in repository.all(
            EntityKind.publishers,
            includeDeleted: true,
          ))
            '${row.id}': EntityKind.publishers.titleOf(row),
        }),
        year('yearFrom', 'Год от'),
        year('yearTo', 'Год до'),
      ],
      EntityKind.authors => [
        dropdown('country', 'Страна', {
          for (final row in repository.all(
            EntityKind.authors,
            includeDeleted: true,
          ))
            row.toJson()['country'] as String:
                row.toJson()['country'] as String,
        }),
        year('birthYearFrom', 'Рождение от'),
        year('birthYearTo', 'Рождение до'),
      ],
      EntityKind.genres => [
        SizedBox(
          width: 250,
          child: TextFormField(
            key: ValueKey('description:${_query.filters["description"]}'),
            initialValue: _query.filters['description'],
            decoration: const InputDecoration(
              labelText: 'Слова в описании',
              helperText: 'Enter — применить',
              border: OutlineInputBorder(),
            ),
            validator: V.length(max: 1000),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            onFieldSubmitted: (value) {
              if (value.length <= 1000) _filter('description', value);
            },
          ),
        ),
      ],
      EntityKind.publishers => [
        dropdown('city', 'Город', {
          for (final row in repository.all(
            EntityKind.publishers,
            includeDeleted: true,
          ))
            row.toJson()['city'] as String: row.toJson()['city'] as String,
        }),
      ],
      EntityKind.readers => [
        dropdown('cardStatus', 'Читательский билет', {
          'active': 'Действующий',
          'expired': 'Истёкший',
        }),
      ],
    };
  }
}
