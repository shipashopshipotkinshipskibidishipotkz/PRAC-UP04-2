import 'package:flutter/material.dart';
import '../models/page_result.dart';

class PaginationControls<T> extends StatelessWidget {
  final PageResult<T> pageResult;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onSizeChanged;
  const PaginationControls({
    super.key,
    required this.pageResult,
    required this.onPageChanged,
    required this.onSizeChanged,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Wrap(
      spacing: 16,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: [
        Text('Всего: ${pageResult.total} записей'),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('На странице: '),
            Semantics(
              label: 'Записей на странице',
              child: DropdownButton<int>(
                value: pageResult.size,
                items: [
                  for (final size in const [10, 25, 50])
                    DropdownMenuItem(value: size, child: Text('$size')),
                ],
                onChanged: (value) {
                  if (value != null) onSizeChanged(value);
                },
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Первая страница',
              icon: const Icon(Icons.first_page),
              onPressed: pageResult.hasPrevious ? () => onPageChanged(1) : null,
            ),
            IconButton(
              tooltip: 'Предыдущая страница',
              icon: const Icon(Icons.chevron_left),
              onPressed:
                  pageResult.hasPrevious
                      ? () => onPageChanged(pageResult.page - 1)
                      : null,
            ),
            Text(
              '${pageResult.page} / ${pageResult.totalPages == 0 ? 1 : pageResult.totalPages}',
            ),
            IconButton(
              tooltip: 'Следующая страница',
              icon: const Icon(Icons.chevron_right),
              onPressed:
                  pageResult.hasNext
                      ? () => onPageChanged(pageResult.page + 1)
                      : null,
            ),
            IconButton(
              tooltip: 'Последняя страница',
              icon: const Icon(Icons.last_page),
              onPressed:
                  pageResult.hasNext
                      ? () => onPageChanged(pageResult.totalPages)
                      : null,
            ),
          ],
        ),
      ],
    ),
  );
}
