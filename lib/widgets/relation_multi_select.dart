import 'package:flutter/material.dart';

class RelationMultiSelect extends StatelessWidget {
  final String label;
  final Map<int, String> options;
  final List<int> selected;
  final ValueChanged<List<int>> onChanged;
  final String? error;
  final String? helper;
  const RelationMultiSelect({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.error,
    this.helper,
  });

  @override
  Widget build(BuildContext context) => FormField<List<int>>(
    key: ValueKey('$label:${options.keys.join(",")}:${selected.join(",")}'),
    initialValue: selected,
    validator:
        (value) =>
            error ??
            ((value?.isEmpty ?? true)
                ? 'Выберите хотя бы одно значение'
                : null),
    builder:
        (field) => InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            errorText: field.errorText,
            helperText: helper,
            helperMaxLines: 3,
            border: const OutlineInputBorder(),
          ),
          child:
              options.isEmpty
                  ? const Text(
                    'Нет доступных значений. Добавьте запись в справочник.',
                  )
                  : Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      for (final entry in options.entries)
                        FilterChip(
                          label: Text(entry.value),
                          selected: field.value!.contains(entry.key),
                          onSelected: (selected) {
                            final next = [...field.value!];
                            selected
                                ? next.add(entry.key)
                                : next.remove(entry.key);
                            field.didChange(next);
                            onChanged(next);
                          },
                        ),
                    ],
                  ),
        ),
  );
}
