import 'package:flutter/material.dart';
import '../core/api_exceptions.dart';
import '../core/request_cancellation.dart';
import '../core/validators.dart';
import '../models/book.dart';
import '../models/catalog_query.dart';
import '../models/entity_kind.dart';
import '../models/reader.dart';
import '../repositories/library_repository.dart';

class LoanDialog extends StatefulWidget {
  final LibraryRepository repository;
  final Book book;
  const LoanDialog({super.key, required this.repository, required this.book});
  @override
  State<LoanDialog> createState() => _LoanDialogState();
}

class _LoanDialogState extends State<LoanDialog> {
  final _form = GlobalKey<FormState>();
  final _search = TextEditingController();
  final _days = TextEditingController(text: '14');
  RequestCancellation? _request;
  List<Reader> _readers = [];
  int? _readerId;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _loadReaders();
  }

  Future<void> _loadReaders() async {
    _request?.cancel();
    final request = RequestCancellation();
    _request = request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await widget.repository.find(
        EntityKind.readers,
        CatalogQuery(search: _search.text.trim()),
        cancellation: request,
      );
      if (!mounted || request.isCancelled) return;
      setState(() {
        _readers = page.items.cast<Reader>();
        _readerId = null;
        _loading = false;
      });
    } on RequestCancelledException {
      return;
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = '$error';
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _request?.cancel();
    _search.dispose();
    _days.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || _loading || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.createLoan(
        bookId: widget.book.id,
        readerId: _readerId!,
        days: int.parse(_days.text.trim()),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(
          () =>
              _error =
                  error is ApiException
                      ? error.message
                      : 'Не удалось оформить выдачу.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      title: const Text('Оформить выдачу'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.book.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text('Свободных экземпляров: ${widget.book.copiesAvailable}'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _search,
                  enabled: !_saving,
                  decoration: const InputDecoration(
                    labelText: 'Поиск читателя',
                    helperText: 'Первые 10 совпадений. Enter — найти',
                    border: OutlineInputBorder(),
                  ),
                  validator: V.length(max: 150),
                  onFieldSubmitted: (_) => _loadReaders(),
                ),
                const SizedBox(height: 16),
                if (_loading)
                  const LinearProgressIndicator(
                    semanticsLabel: 'Загрузка читателей',
                  )
                else
                  DropdownButtonFormField<int>(
                    key: ValueKey(
                      _readers.map((reader) => reader.id).join(','),
                    ),
                    value: _readerId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Читатель',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final reader in _readers)
                        DropdownMenuItem(
                          value: reader.id,
                          child: Text(reader.fullName),
                        ),
                    ],
                    onChanged:
                        _saving ? null : (id) => setState(() => _readerId = id),
                    validator: (id) => id == null ? 'Выберите читателя' : null,
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _days,
                  enabled: !_saving,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Срок выдачи в днях',
                    border: OutlineInputBorder(),
                  ),
                  validator: V.integer(min: 1, max: 90),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                if (!_loading && _readers.isEmpty)
                  TextButton(
                    onPressed: _loadReaders,
                    child: const Text('Повторить поиск читателя'),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: _saving || _loading ? null : _submit,
          child: Text(_saving ? 'Оформление…' : 'Выдать книгу'),
        ),
      ],
    ),
  );
}
