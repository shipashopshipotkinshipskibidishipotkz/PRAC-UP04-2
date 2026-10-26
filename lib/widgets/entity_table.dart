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
    this.selected = const {},
    this.onToggleSelect,
    this.sortField,
    this.sortAscending = true,
    this.onSort,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: MediaQuery.sizeOf(context).width),
          child: DataTable(
            sortColumnIndex: sortField != null
                ? columns.indexWhere((c) => c.sortField == sortField)
                : null,
            sortAscending: sortAscending,
            columns: [
              if (onToggleSelect != null)
                const DataColumn(label: SizedBox(width: 40)),
              for (final col in columns)
                DataColumn(
                  label: Text(col.label),
                  numeric: col.numeric,
                  onSort: col.sortField != null && onSort != null
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
                  onSelectChanged: onToggleSelect != null
                      ? (_) => onToggleSelect!(idOf(item))
                      : null,
                  cells: [
                    if (onToggleSelect != null)
                      const DataCell(SizedBox(width: 40)),
                    for (final col in columns)
                      DataCell(col.build(item)),
                    if (actions != null)
                      DataCell(Row(
                        mainAxisSize: MainAxisSize.min,
                        children: actions!(item),
                      )),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}