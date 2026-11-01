import 'package:flutter/material.dart';

class TableColumnSpec<T> {
  final String label;
  final String? sortField;
  final bool numeric;
  final Widget Function(T item) build;

  const TableColumnSpec({
    required this.label,
    required this.build,
    this.sortField,
    this.numeric = false,
  });
}

class EntityTable<T> extends StatelessWidget {
  final List<TableColumnSpec<T>> columns;
  final List<T> items;
  final int Function(T item) idOf;
  final String Function(T item)? labelOf;
  final Set<int> selected;
  final ValueChanged<int>? onToggleSelect;
  final String? sortField;
  final bool sortAscending;
  final void Function(String field)? onSort;
  final List<Widget> Function(T item)? actions;

  const EntityTable({
    super.key,
    required this.columns,
    required this.items,
    required this.idOf,
    this.labelOf,
    this.selected = const {},
    this.onToggleSelect,
    this.sortField,
    this.sortAscending = true,
    this.onSort,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final selectedRows =
        items.where((item) => selected.contains(idOf(item))).length;
    final hasSelection = onToggleSelect != null;
    return LayoutBuilder(
      builder:
          (context, constraints) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                showCheckboxColumn: false,
                sortColumnIndex:
                    sortField != null &&
                            columns.any((c) => c.sortField == sortField)
                        ? columns.indexWhere((c) => c.sortField == sortField) +
                            (hasSelection ? 1 : 0)
                        : null,
                sortAscending: sortAscending,
                columns: [
                  if (hasSelection)
                    DataColumn(
                      label: Checkbox(
                        semanticLabel: 'Выбрать все записи на странице',
                        tristate: true,
                        value:
                            selectedRows == 0
                                ? false
                                : selectedRows == items.length
                                ? true
                                : null,
                        onChanged: (_) {
                          final selectAll = selectedRows != items.length;
                          for (final item in items) {
                            if (selected.contains(idOf(item)) != selectAll) {
                              onToggleSelect!(idOf(item));
                            }
                          }
                        },
                      ),
                    ),
                  for (final col in columns)
                    DataColumn(
                      label: Text(col.label),
                      numeric: col.numeric,
                      onSort:
                          col.sortField != null && onSort != null
                              ? (_, __) => onSort!(col.sortField!)
                              : null,
                    ),
                  if (actions != null)
                    const DataColumn(label: Text('Действия')),
                ],
                rows: [
                  for (final item in items)
                    DataRow(
                      selected: selected.contains(idOf(item)),
                      onSelectChanged:
                          onToggleSelect != null
                              ? (_) => onToggleSelect!(idOf(item))
                              : null,
                      cells: [
                        if (hasSelection)
                          DataCell(
                            Checkbox(
                              semanticLabel:
                                  'Выбрать запись: ${labelOf?.call(item) ?? idOf(item)}',
                              value: selected.contains(idOf(item)),
                              onChanged: (_) => onToggleSelect!(idOf(item)),
                            ),
                          ),
                        for (final col in columns) DataCell(col.build(item)),
                        if (actions != null)
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: actions!(item),
                            ),
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
