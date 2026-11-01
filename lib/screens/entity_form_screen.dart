import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/entity_fields.dart';
import '../core/form_exit_guard.dart';
import '../core/json_values.dart';
import '../models/entity_kind.dart';
import '../repositories/persistent_library_repository.dart';
import '../widgets/relation_multi_select.dart';

class EntityFormScreen extends StatefulWidget {
  final EntityKind kind;
  final int? id;
  const EntityFormScreen({super.key, required this.kind, this.id});
  @override
  State<EntityFormScreen> createState() => _EntityFormScreenState();
}

class _EntityFormScreenState extends State<EntityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  final _focusNodes = <String, FocusNode>{};
  final _token = Object();
  late final PersistentLibraryRepository _repository;
  late final FormExitGuard _guard;
  late final List<EntityField> _fields;
  late final String _initialSignature;
  int? _publisherId;
  List<int> _authorIds = [];
  List<int> _genreIds = [];
  bool _dirty = false;
  bool _saving = false;
  bool _allowExit = false;
  bool _missing = false;
  bool _deleted = false;
  bool _submitted = false;
  Map<String, String> _saveErrors = {};
  Future<bool>? _confirmation;

  @override
  void initState() {
    super.initState();
    _repository = context.read<PersistentLibraryRepository>();
    _guard = context.read<FormExitGuard>();
    _guard.owner = _token;
    _guard.confirm = _confirmLeave;
    _fields = fieldsFor(widget.kind);
    final entity =
        widget.id == null ? null : _repository.byId(widget.kind, widget.id!);
    _missing = widget.id != null && entity == null;
    _deleted = entity?.isDeleted ?? false;
    final data = entity?.toJson() ?? <String, dynamic>{};
    for (final field in _fields) {
      _focusNodes[field.name] = FocusNode();
      _controllers[field.name] = TextEditingController(
        text: fieldText(data, field.name),
      );
    }
    _publisherId = JsonValues.optionalInteger(data['publisherId']);
    _authorIds = JsonValues.ids(data['authorIds']);
    _genreIds = JsonValues.ids(data['genreIds']);
    _initialSignature = _signature();
  }

  @override
  void dispose() {
    _guard.detach(_token);
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> _data() {
    final data = <String, dynamic>{};
    for (final field in _fields) {
      final text = _controllers[field.name]!.text.trim();
      final Object? value =
          field.numeric
              ? (text.isEmpty ? null : int.tryParse(text) ?? text)
              : text;
      if (field.name.contains('.')) {
        (data['card'] ??= <String, dynamic>{})[field.name.split('.').last] =
            value;
      } else {
        data[field.name] = value;
      }
    }
    if (widget.kind == EntityKind.readers) {
      data['email'] = (data['email'] as String).toLowerCase();
      data['card']['number'] = (data['card']['number'] as String).toUpperCase();
    }
    if (widget.kind == EntityKind.books) {
      data.addAll({
        'publisherId': _publisherId,
        'authorIds': _authorIds,
        'genreIds': _genreIds,
      });
    }
    return data;
  }

  String _signature() => jsonEncode({
    for (final entry in _controllers.entries) entry.key: entry.value.text,
    'publisherId': _publisherId,
    'authorIds': _authorIds,
    'genreIds': _genreIds,
  });

  void _changed() {
    setState(() {
      _dirty = _signature() != _initialSignature;
      _saveErrors = {};
    });
  }

  Future<bool> _confirmLeave() async {
    if (_saving) return false;
    if (!_dirty || _allowExit) return true;
    if (_confirmation != null) return _confirmation!;
    _confirmation = showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Есть несохранённые изменения'),
            content: const Text(
              'Если уйти с формы, введённые изменения будут потеряны.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Остаться'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Уйти без сохранения'),
              ),
            ],
          ),
    ).then((value) => value ?? false);
    final leave = await _confirmation!;
    _confirmation = null;
    if (leave && mounted) setState(() => _allowExit = true);
    return leave;
  }

  Future<void> _submit() async {
    if (_saving) return;
    setState(() {
      _submitted = true;
      _saveErrors = {};
    });
    if (!_formKey.currentState!.validate()) {
      final errors = _repository.validate(widget.kind, _data(), id: widget.id);
      for (final field in _fields) {
        if (errors.containsKey(field.name)) {
          _focusNodes[field.name]!.requestFocus();
          break;
        }
      }
      return;
    }
    setState(() => _saving = true);
    try {
      final entity = await _repository.save(
        widget.kind,
        _data(),
        id: widget.id,
      );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _dirty = false;
        _allowExit = true;
      });
      context.go('${widget.kind.path}/${entity.id}');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Изменения сохранены')));
    } on FieldValidationException catch (error) {
      if (!mounted) return;
      setState(() => _saveErrors = error.errors);
      _formKey.currentState!.validate();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось сохранить данные: $error')),
      );
    } finally {
      if (mounted && _saving) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<PersistentLibraryRepository>();
    final editing = widget.id != null;
    final errors = _repository.validate(widget.kind, _data(), id: widget.id);
    final publisherOptions = _repository.publisherList;
    final availablePublisherId =
        publisherOptions.any((row) => row.id == _publisherId)
            ? _publisherId
            : null;
    return PopScope(
      canPop: (!_dirty || _allowExit) && !_saving,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && await _confirmLeave() && context.mounted) {
          context.go(widget.kind.path);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Назад к списку',
            icon: const Icon(Icons.arrow_back),
            onPressed: _saving ? null : () => context.go(widget.kind.path),
          ),
          title: Text(
            '${editing ? 'Редактирование' : 'Создание'}: ${widget.kind.singular.toLowerCase()}',
          ),
        ),
        body:
            _missing || _deleted
                ? Center(
                  child: Text(
                    _missing
                        ? 'Запись не найдена'
                        : 'Перед редактированием восстановите запись из корзины',
                  ),
                )
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 780),
                      child: Form(
                        key: _formKey,
                        autovalidateMode:
                            _submitted
                                ? AutovalidateMode.always
                                : AutovalidateMode.onUserInteraction,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              editing
                                  ? 'Измените данные записи'
                                  : 'Новая запись',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Изменения сохраняются в этом браузере. ${_dirty ? 'Есть несохранённые изменения.' : ''}',
                            ),
                            const SizedBox(height: 24),
                            for (final field in _fields) ...[
                              if (field.name == 'card.number') ...[
                                const Divider(height: 32),
                                Text(
                                  'Читательский билет',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const Text(
                                  'Один читатель — один билет. Данные сохраняются вместе.',
                                ),
                                const SizedBox(height: 16),
                              ],
                              TextFormField(
                                key: ValueKey(field.name),
                                        controller: _controllers[field.name],
                                        focusNode: _focusNodes[field.name],
                                enabled: !_saving,
                                maxLines: field.lines,
                                keyboardType:
                                    field.numeric
                                        ? TextInputType.number
                                        : field.name == 'email'
                                        ? TextInputType.emailAddress
                                        : field.name == 'phone'
                                        ? TextInputType.phone
                                        : TextInputType.text,
                                decoration: InputDecoration(
                                  labelText: field.label,
                                  hintText: field.hint,
                                  border: const OutlineInputBorder(),
                                  errorMaxLines: 3,
                                ),
                                validator:
                                    (_) =>
                                        _saveErrors[field.name] ??
                                            _repository.validate(widget.kind, _data(), id: widget.id)[field.name],
                                onChanged: (_) => _changed(),
                              ),
                              const SizedBox(height: 18),
                            ],
                            if (widget.kind == EntityKind.books) ...[
                              DropdownButtonFormField<int>(
                                key: ValueKey('publisher:$_publisherId'),
                                value: availablePublisherId,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Издательство',
                                  border: OutlineInputBorder(),
                                ),
                                items: [
                                  for (final publisher in publisherOptions)
                                    DropdownMenuItem(
                                      value: publisher.id,
                                      child: Text(publisher.name),
                                    ),
                                ],
                                validator:
                                    (_) =>
                                        _saveErrors['publisherId'] ??
                                        errors['publisherId'],
                                onChanged:
                                    _saving
                                        ? null
                                        : (id) {
                                          _publisherId = id;
                                          final allowed =
                                              _repository
                                                  .authorsForPublisher(id)
                                                  .map((row) => row.id)
                                                  .toSet();
                                          _authorIds =
                                              _authorIds
                                                  .where(allowed.contains)
                                                  .toList();
                                          _changed();
                                        },
                              ),
                              const SizedBox(height: 18),
                              AbsorbPointer(
                                absorbing: _saving,
                                child: RelationMultiSelect(
                                  label: 'Авторы',
                                  helper:
                                      _publisherId == null
                                          ? 'Сначала выберите издательство.'
                                          : 'Авторы этого издательства и авторы без книг. Для издательства без книг доступны все авторы.',
                                  options: {
                                    for (final author in _repository
                                        .authorsForPublisher(_publisherId))
                                      author.id: author.fullName,
                                  },
                                  selected: _authorIds,
                                  error:
                                      _saveErrors['authorIds'] ??
                                      errors['authorIds'],
                                  onChanged: (ids) {
                                    _authorIds = ids;
                                    _changed();
                                  },
                                ),
                              ),
                              const SizedBox(height: 18),
                              AbsorbPointer(
                                absorbing: _saving,
                                child: RelationMultiSelect(
                                  label: 'Жанры',
                                  options: {
                                    for (final genre in _repository.genreList)
                                      genre.id: genre.name,
                                  },
                                  selected: _genreIds,
                                  error:
                                      _saveErrors['genreIds'] ??
                                      errors['genreIds'],
                                  onChanged: (ids) {
                                    _genreIds = ids;
                                    _changed();
                                  },
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                FilledButton.icon(
                                  onPressed: _saving ? null : _submit,
                                  icon:
                                      _saving
                                          ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                          : const Icon(Icons.save_outlined),
                                  label: Text(
                                    _saving
                                        ? 'Сохранение…'
                                        : editing
                                        ? 'Сохранить изменения'
                                        : 'Создать запись',
                                  ),
                                ),
                                OutlinedButton(
                                  onPressed:
                                      _saving
                                          ? null
                                          : () => context.go(widget.kind.path),
                                  child: const Text('Отмена'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
      ),
    );
  }
}
