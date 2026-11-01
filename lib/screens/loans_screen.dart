import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/api_exceptions.dart';
import '../models/page_result.dart';
import '../repositories/account_repository.dart';
import '../widgets/api_connection_button.dart';
import '../widgets/pagination_controls.dart';
import '../widgets/states.dart';
import '../widgets/workspace_scaffold.dart';

class LoansScreen extends StatefulWidget {
  final bool own;
  const LoansScreen({super.key, this.own = false});
  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  PageResult<Map<String, dynamic>> _result = PageResult.empty();
  int _page = 1;
  int _size = 10;
  String? _status;
  String? _error;
  bool _loading = true;
  final _busy = <int>{};
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await context.read<AccountRepository>().list(
        '/loans',
        page: _page,
        size: _size,
        status: _status,
      );
      if (mounted && generation == _generation) {
        setState(() {
          _result = result;
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted && generation == _generation) {
        setState(() {
          _error =
              error is ApiException
                  ? error.message
                  : 'Не удалось загрузить выдачи.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _action(int id) async {
    if (_busy.contains(id)) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (c) => AlertDialog(
            title: Text(widget.own ? 'Продлить выдачу?' : 'Закрыть выдачу?'),
            content: Text(
              widget.own
                  ? 'Срок возврата будет увеличен на 14 дней.'
                  : 'Подтвердите возврат книги в библиотеку.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('Отмена'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text('Подтвердить'),
              ),
            ],
          ),
    );
    if (confirmed != true || !mounted || _busy.contains(id)) return;
    setState(() => _busy.add(id));
    try {
      final api = context.read<AccountRepository>();
      if (widget.own) {
        await api.renew(id);
      } else {
        await api.closeLoan(id);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.own ? 'Срок продлён на 14 дней' : 'Возврат оформлен',
          ),
        ),
      );
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is ApiException
                  ? error.message
                  : 'Не удалось выполнить операцию.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy.remove(id));
    }
  }

  String _date(Object? raw) {
    final date = DateTime.tryParse('$raw')?.toLocal();
    return date == null
        ? '—'
        : '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  @override
  Widget build(BuildContext context) => WorkspaceScaffold(
    location: widget.own ? '/my-loans' : '/loans',

    appBar: AppBar(
      title: Text(widget.own ? 'Мои выдачи' : 'Выдачи и возвраты'),
      actions: const [ApiConnectionButton()],
    ),
    child: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (!widget.own)
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: () => context.go('/books'),
              icon: const Icon(Icons.add),
              label: const Text('Оформить выдачу из каталога'),
            ),
          ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: [
            for (final entry
                in <String?, String>{
                  null: 'Все',
                  'active': 'Активные',
                  'overdue': 'Просроченные',
                  'returned': 'Возвращённые',
                }.entries)
              ChoiceChip(
                label: Text(entry.value),
                selected: _status == entry.key,
                onSelected: (_) {
                  _status = entry.key;
                  _page = 1;
                  _load();
                },
              ),
            IconButton(
              tooltip: 'Обновить',
              onPressed: _load,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_loading)
          const SizedBox(height: 240, child: LoadingState())
        else if (_error != null)
          ErrorState(message: _error!, onRetry: _load)
        else if (_result.items.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: EmptyState(message: 'Выдачи не найдены'),
          )
        else ...[
          for (final loan in _result.items)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${(loan['book'] as Map?)?['title'] ?? 'Книга удалена'}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (!widget.own)
                      Text(
                        'Читатель: ${(loan['reader'] as Map?)?['fullName'] ?? '—'}',
                      ),
                    const SizedBox(height: 8),
                    Text(
                      'Выдана: ${_date(loan['issuedAt'])} · Вернуть до: ${_date(loan['dueAt'])}',
                    ),
                    Text(
                      'Статус: ${switch (loan['status']) {
                        'returned' => 'Возвращена',
                        'overdue' => 'Просрочена',
                        _ => 'На руках',
                      }}',
                    ),
                    if (loan['returnedAt'] == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: OutlinedButton.icon(
                          onPressed:
                              _busy.contains(loan['id'])
                                  ? null
                                  : () => _action(loan['id'] as int),
                          icon: Icon(
                            widget.own
                                ? Icons.update
                                : Icons.assignment_turned_in_outlined,
                          ),
                          label: Text(
                            widget.own
                                ? 'Продлить на 14 дней'
                                : 'Оформить возврат',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          PaginationControls(
            pageResult: _result,
            onPageChanged: (page) {
              _page = page;
              _load();
            },
            onSizeChanged: (size) {
              _size = size;
              _page = 1;
              _load();
            },
          ),
        ],
      ],
    ),
  );
}
