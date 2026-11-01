import 'package:flutter/material.dart';

class FilterPanel extends StatelessWidget {
  final Widget searchField;
  final List<Widget> filters;
  final Widget? toggleDeleted;
  final VoidCallback onApply;
  final VoidCallback onReset;

  const FilterPanel({
    super.key,
    required this.searchField,
    required this.filters,
    this.toggleDeleted,
    required this.onApply,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 700) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  searchField,
                  const SizedBox(height: 12),
                  ...filters,
                  if (toggleDeleted != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: toggleDeleted!,
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: onApply,
                          child: const Text('Применить'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onReset,
                          child: const Text('Сбросить'),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(width: 240, child: searchField),
                ...filters,
                if (toggleDeleted != null) toggleDeleted!,
                FilledButton(
                  onPressed: onApply,
                  child: const Text('Применить'),
                ),
                OutlinedButton(
                  onPressed: onReset,
                  child: const Text('Сбросить'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
