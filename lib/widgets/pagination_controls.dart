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
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Всего: ${pageResult.total} записей'),
          Row(
            children: [
              DropdownButton<int>(
                value: pageResult.size,
                items: const [10, 25, 50]
                    .map((s) => DropdownMenuItem(value: s, child: Text('$s')))
                    .toList(),
                onChanged: (value) {
                  if (value != null) onSizeChanged(value);
                },
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.first_page),
                onPressed: pageResult.page > 1 ? () => onPageChanged(1) : null,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: pageResult.hasPrevious
                    ? () => onPageChanged(pageResult.page - 1)
                    : null,
              ),
              Text('Страница ${pageResult.page} из ${pageResult.totalPages}'),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: pageResult.hasNext
                    ? () => onPageChanged(pageResult.page + 1)
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.last_page),
                onPressed: pageResult.page < pageResult.totalPages
                    ? () => onPageChanged(pageResult.totalPages)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}