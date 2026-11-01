import 'package:flutter/material.dart';
import '../models/entity_kind.dart';
import '../repositories/library_repository.dart';
import '../core/api_exceptions.dart';

abstract final class EntityActions {
  static Future<void> delete(
    BuildContext context,
    LibraryRepository repository,
    EntityKind kind,
    Iterable<int> ids, {
    bool hard = false,
  }) async {
    final selected = ids.toList();
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(hard ? 'Удалить навсегда?' : 'Переместить в корзину?'),
            content: Text(
              'Записей: ${selected.length}. ${hard ? 'Восстановить их будет невозможно.' : 'Записи можно будет восстановить.'}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Отмена'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Удалить'),
              ),
            ],
          ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await repository.delete(kind, selected, hard: hard);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Записи удалены')));
      }
    } catch (error) {
      if (context.mounted) await showError(context, error);
    }
  }

  static Future<void> restore(
    BuildContext context,
    LibraryRepository repository,
    EntityKind kind,
    int id,
  ) async {
    try {
      await repository.restore(kind, id);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Запись восстановлена')));
      }
    } catch (error) {
      if (context.mounted) await showError(context, error);
    }
  }

  static Future<void> showError(BuildContext context, Object error) =>
      showDialog<void>(
        context: context,
        builder:
            (dialogContext) => AlertDialog(
              title: Text(
                error is ConflictException
                    ? 'Удаление невозможно'
                    : 'Не удалось выполнить операцию',
              ),
              content: Text(error.toString()),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Понятно'),
                ),
              ],
            ),
      );
}
