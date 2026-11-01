import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/entity_fields.dart';
import '../core/json_values.dart';
import '../core/validators.dart';
import '../models/author.dart';
import '../models/book.dart';
import '../models/catalog_query.dart';
import '../models/entity_kind.dart';
import '../models/genre.dart';
import '../models/library_card.dart';
import '../models/library_entity.dart';
import '../models/page_result.dart';
import '../models/publisher.dart';
import '../models/reader.dart';
import '../models/seed_data.dart';

class FieldValidationException implements Exception {
  final Map<String, String> errors;
  const FieldValidationException(this.errors);
}

class RelationException implements Exception {
  final int count;
  const RelationException(this.count);
  @override
  String toString() =>
      'Удаление невозможно: связанных книг — $count. Сначала измените их связи или физически удалите книги. Учитываются и книги в корзине.';
}

class PersistentLibraryRepository extends ChangeNotifier {
  static const storageKey = 'library_catalog_v3';
  static const schemaVersion = 3;
  final SharedPreferencesAsync _preferences;
  Map<EntityKind, List<LibraryEntity>> _rows;
  Map<EntityKind, int> _nextIds;
  Future<void> _pending = Future.value();
  String? storageNotice;

  PersistentLibraryRepository._(this._preferences, this._rows, this._nextIds);

  static Map<EntityKind, List<LibraryEntity>> _seed() => {
    EntityKind.books: [...seedBooks],
    EntityKind.authors: [...seedAuthors],
    EntityKind.genres: [
      for (final entry in genres.entries)
        Genre(
          id: entry.key,
          name: entry.value,
          description: 'Литературный жанр: ${entry.value.toLowerCase()}',
        ),
    ],
    EntityKind.publishers: [
      const Publisher(id: 1, name: 'АСТ', city: 'Москва', foundedYear: 1990),
      const Publisher(id: 2, name: 'Эксмо', city: 'Москва', foundedYear: 1991),
      const Publisher(
        id: 3,
        name: 'Просвещение',
        city: 'Москва',
        foundedYear: 1930,
      ),
      const Publisher(
        id: 4,
        name: 'Художественная литература',
        city: 'Москва',
        foundedYear: 1930,
      ),
      const Publisher(
        id: 5,
        name: 'Иностранка',
        city: 'Москва',
        foundedYear: 2000,
      ),
    ],
    EntityKind.readers: [
      Reader(
        id: 1,
        fullName: 'Павел Смирнов',
        email: 'smirnov@example.com',
        phone: '+7 900 000-00-00',
        card: LibraryCard(
          id: 1,
          number: 'RC-000001',
          issuedAt: DateTime(2026, 1, 15),
          expiresAt: DateTime(2027, 1, 15),
        ),
      ),
      Reader(
        id: 2,
        fullName: 'Анна Иванова',
        email: 'ivanova@example.com',
        phone: '+7 901 111-22-33',
        card: LibraryCard(
          id: 2,
          number: 'RC-000002',
          issuedAt: DateTime(2026, 2, 1),
          expiresAt: DateTime(2027, 2, 1),
        ),
      ),
    ],
  };

  static Future<PersistentLibraryRepository> open([
    SharedPreferencesAsync? preferences,
  ]) async {
    final prefs = preferences ?? SharedPreferencesAsync();
    var rows = _seed();
    final nextIds = <EntityKind, int>{};
    String? notice;
    String? raw;
    try {
      raw = await prefs.getString(storageKey);
    } on TypeError {
      notice =
          'Сохранённый каталог имеет неверный тип. Загружен начальный каталог.';
    }
    if (raw != null) {
      try {
        final root = JsonValues.object(jsonDecode(raw));
        if (root['schemaVersion'] != schemaVersion) {
          throw const FormatException('Версия формата');
        }
        final data = JsonValues.object(root['data']);
        final counters = JsonValues.object(root['nextIds']);
        rows = {
          for (final kind in EntityKind.values)
            kind: _decodeRows(kind, data[kind.name]),
        };
        for (final kind in EntityKind.values) {
          nextIds[kind] = JsonValues.integer(counters[kind.name]);
        }
      } catch (_) {
        await prefs.setString('${storageKey}_backup', raw);
        notice =
            'Формат сохранённых данных устарел или повреждён. Загружен начальный каталог; прежние данные оставлены в резервном ключе ${storageKey}_backup.';
      }
    } else {
      final keys = await prefs.getKeys();
      if (keys.any(
        (key) => const [
          'library_catalog_v1',
          'library_catalog_v2',
          'books_v1',
          'authors_v1',
        ].contains(key),
      )) {
        notice =
            'Обнаружен прежний формат данных. Для ПР3 создан каталог версии $schemaVersion. Старые записи сохранены в прежних ключах.';
      }
    }
    for (final kind in EntityKind.values) {
      final maxId = rows[kind]!.fold(
        0,
        (maxId, row) => math.max(maxId, row.id),
      );
      nextIds[kind] = math.max(nextIds[kind] ?? 1, maxId + 1);
    }
    final repository = PersistentLibraryRepository._(prefs, rows, nextIds)
      ..storageNotice = notice;
    await repository._persist(rows, nextIds);
    return repository;
  }

  static List<LibraryEntity> _decodeRows(EntityKind kind, Object? raw) {
    if (raw is! List) throw const FormatException('Нет коллекции');
    final ids = <int>{};
    return raw.map((item) {
      final row = kind.fromJson(JsonValues.object(item));
      if (row.id <= 0 || !ids.add(row.id)) {
        throw const FormatException('Некорректный идентификатор');
      }
      return row;
    }).toList();
  }

  List<LibraryEntity> all(EntityKind kind, {bool includeDeleted = false}) =>
      List.unmodifiable(
        _rows[kind]!.where((row) => includeDeleted || !row.isDeleted),
      );
  LibraryEntity? byId(EntityKind kind, int id) {
    for (final row in _rows[kind]!) {
      if (row.id == id) return row;
    }
    return null;
  }

  List<Book> get books => all(EntityKind.books).cast<Book>();
  List<Author> get authors => all(EntityKind.authors).cast<Author>();
  List<Genre> get genreList => all(EntityKind.genres).cast<Genre>();
  List<Publisher> get publisherList =>
      all(EntityKind.publishers).cast<Publisher>();
  List<Reader> get readers => all(EntityKind.readers).cast<Reader>();

  String title(EntityKind kind, int id) {
    final row = byId(kind, id);
    return row == null
        ? 'Запись #$id не найдена'
        : '${kind.titleOf(row)}${row.isDeleted ? ' (в корзине)' : ''}';
  }

  List<Author> authorsForPublisher(int? publisherId) {
    if (publisherId == null) return [];
    final publisherBooks = books.where(
      (book) => book.publisherId == publisherId,
    );
    if (publisherBooks.isEmpty) return authors;
    final matching = publisherBooks.expand((book) => book.authorIds).toSet();
    final assigned = books.expand((book) => book.authorIds).toSet();
    return authors
        .where(
          (author) =>
              matching.contains(author.id) || !assigned.contains(author.id),
        )
        .toList();
  }

  PageResult<LibraryEntity> find(EntityKind kind, CatalogQuery query) {
    final needle = query.search.trim().toLowerCase();
    var rows =
        all(kind, includeDeleted: query.includeDeleted).where((row) {
          final data = row.toJson();
          final searchable =
              [for (final field in fieldsFor(kind)) fieldText(data, field.name)]
                  .join(' ')
                  .toLowerCase();
          if (!searchable.contains(needle)) return false;
          for (final entry in query.filters.entries) {
            final value = entry.value;
            if (value.isEmpty) continue;
            final number = int.tryParse(value);
            switch (entry.key) {
              case 'genreId':
                if (number != null &&
                    !(data['genreIds'] as List? ?? []).contains(number)) {
                  return false;
                }
              case 'publisherId':
                if (number != null && data['publisherId'] != number) {
                  return false;
                }
              case 'country':
                if (data['country'] != value) return false;
              case 'city':
                if (data['city'] != value) return false;
              case 'yearFrom':
                if (number != null &&
                    JsonValues.integer(data['year']) < number) {
                  return false;
                }
              case 'yearTo':
                if (number != null &&
                    JsonValues.integer(data['year']) > number) {
                  return false;
                }
              case 'birthYearFrom':
                if (number != null &&
                    JsonValues.integer(data['birthYear']) < number) {
                  return false;
                }
              case 'birthYearTo':
                if (number != null &&
                    JsonValues.integer(data['birthYear']) > number) {
                  return false;
                }
              case 'description':
                if (!JsonValues.text(
                  data['description'],
                ).toLowerCase().contains(value.toLowerCase())) {
                  return false;
                }
              case 'cardStatus':
                final date = JsonValues.date(
                  JsonValues.object(data['card'])['expiresAt'],
                );
                final now = DateTime.now();
                final expired =
                    date == null ||
                    date.isBefore(DateTime(now.year, now.month, now.day));
                if ((value == 'expired') != expired) return false;
            }
          }
          return true;
        }).toList();
    final sort = query.sortField.isEmpty ? kind.titleField : query.sortField;
    rows.sort((a, b) {
      final av =
          kind == EntityKind.books && sort == 'publisherId'
              ? title(EntityKind.publishers, (a as Book).publisherId)
              : fieldValue(a.toJson(), sort);
      final bv =
          kind == EntityKind.books && sort == 'publisherId'
              ? title(EntityKind.publishers, (b as Book).publisherId)
              : fieldValue(b.toJson(), sort);
      var result =
          av is num && bv is num
              ? av.compareTo(bv)
              : (av ?? '').toString().toLowerCase().compareTo(
                (bv ?? '').toString().toLowerCase(),
              );
      if (result == 0) result = a.id.compareTo(b.id);
      return query.ascending ? result : -result;
    });
    final total = rows.length;
    final page =
        query.page.clamp(1, math.max(1, (total / query.size).ceil())).toInt();
    final start = (page - 1) * query.size;
    rows = rows.sublist(start, math.min(start + query.size, total));
    return PageResult(items: rows, page: page, size: query.size, total: total);
  }

  String? uniqueError(
    EntityKind kind,
    String field,
    String value, {
    int? excludingId,
  }) {
    String normalize(String value) =>
        field == 'isbn' ? V.normalizeIsbn(value) : value.trim().toLowerCase();
    final duplicate = all(kind, includeDeleted: true).any(
      (row) =>
          row.id != excludingId &&
          normalize(fieldText(row.toJson(), field)) == normalize(value),
    );
    if (!duplicate) return null;
    return switch (field) {
      'isbn' => 'Книга с таким ISBN уже существует',
      'email' => 'Читатель с такой почтой уже существует',
      _ => 'Такой номер билета уже используется',
    };
  }

  Map<String, String> validate(
    EntityKind kind,
    Map<String, dynamic> data, {
    int? id,
  }) {
    final errors = <String, String>{};
    for (final field in fieldsFor(kind)) {
      final error = field.validator(fieldText(data, field.name));
      if (error != null) errors[field.name] = error;
    }
    void unique(String field) {
      final error = uniqueError(
        kind,
        field,
        fieldText(data, field),
        excludingId: id,
      );
      if (error != null) errors[field] = error;
    }

    bool active(EntityKind kind, int id) {
      final row = byId(kind, id);
      return row != null && !row.isDeleted;
    }

    if (kind == EntityKind.books) {
      unique('isbn');
      if (!active(
        EntityKind.publishers,
        JsonValues.integer(data['publisherId']),
      )) {
        errors['publisherId'] = 'Выберите действующее издательство';
      }
      for (final relation in [
        ('authorIds', EntityKind.authors, 'автора'),
        ('genreIds', EntityKind.genres, 'жанр'),
      ]) {
        final ids = JsonValues.ids(data[relation.$1]);
        if (ids.isEmpty || ids.any((id) => !active(relation.$2, id))) {
          errors[relation.$1] =
              relation.$2 == EntityKind.authors
                  ? 'Выберите хотя бы одного действующего автора'
                  : 'Выберите хотя бы один действующий жанр';
        }
      }
      if (JsonValues.integer(data['copiesAvailable']) >
          JsonValues.integer(data['copiesTotal'])) {
        errors['copiesAvailable'] =
            'Доступных экземпляров не может быть больше общего количества';
      }
    }
    if (kind == EntityKind.authors &&
        data['deathYear'] != null &&
        fieldText(data, 'deathYear').isNotEmpty &&
        JsonValues.integer(data['deathYear']) <
            JsonValues.integer(data['birthYear'])) {
      errors['deathYear'] = 'Год смерти не может быть раньше года рождения';
    }
    if (kind == EntityKind.readers) {
      unique('email');
      unique('card.number');
      final issued = V.parseDate(fieldText(data, 'card.issuedAt'));
      final expires = V.parseDate(fieldText(data, 'card.expiresAt'));
      final now = DateTime.now();
      if (issued != null &&
          issued.isAfter(DateTime(now.year, now.month, now.day))) {
        errors['card.issuedAt'] = 'Дата выдачи не может быть в будущем';
      }
      if (issued != null && expires != null && !expires.isAfter(issued)) {
        errors['card.expiresAt'] =
            'Срок действия должен быть позже даты выдачи';
      }
    }
    return errors;
  }

  Future<T> _serial<T>(Future<T> Function() operation) {
    final result = _pending.then((_) => operation());
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<LibraryEntity> save(
    EntityKind kind,
    Map<String, dynamic> data, {
    int? id,
  }) => _serial(() async {
    final existing = id == null ? null : byId(kind, id);
    if (id != null && existing == null) throw StateError('Запись не найдена');
    if (existing?.isDeleted ?? false) {
      throw StateError('Сначала восстановите запись из корзины');
    }
    final errors = validate(kind, data, id: id);
    if (errors.isNotEmpty) throw FieldValidationException(errors);
    final next = {
      for (final entry in _rows.entries) entry.key: [...entry.value],
    };
    final counters = Map<EntityKind, int>.of(_nextIds);
    final assignedId = id ?? counters[kind]!;
    if (id == null) counters[kind] = assignedId + 1;
    final json = {...data, 'id': assignedId, 'deletedAt': null};
    if (kind == EntityKind.readers) {
      json['card'] = {
        ...JsonValues.object(data['card']),
        'id': existing is Reader ? existing.card.id : assignedId,
      };
    }
    final entity = kind.fromJson(json);
    final index = next[kind]!.indexWhere((row) => row.id == assignedId);
    if (index < 0) {
      next[kind]!.add(entity);
    } else {
      next[kind]![index] = entity;
    }
    await _commit(next, counters);
    return entity;
  });

  int linkedBookCount(EntityKind kind, int id) =>
      all(EntityKind.books, includeDeleted: true)
          .cast<Book>()
          .where(
            (book) => switch (kind) {
              EntityKind.publishers => book.publisherId == id,
              EntityKind.authors => book.authorIds.contains(id),
              EntityKind.genres => book.genreIds.contains(id),
              _ => false,
            },
          )
          .length;

  Future<void> delete(
    EntityKind kind,
    Iterable<int> ids, {
    bool hard = false,
  }) => _serial(() async {
    final selected = ids.toSet();
    for (final id in selected) {
      final count = linkedBookCount(kind, id);
      if (count > 0) throw RelationException(count);
    }
    final next = {
      for (final entry in _rows.entries) entry.key: [...entry.value],
    };
    next[kind] = [
      for (final row in next[kind]!)
        if (!selected.contains(row.id))
          row
        else if (!hard)
          kind.fromJson({
            ...row.toJson(),
            'deletedAt':
                row.deletedAt?.toIso8601String() ??
                DateTime.now().toIso8601String(),
          }),
    ];
    await _commit(next, _nextIds);
  });

  Future<void> restore(EntityKind kind, int id) => _serial(() async {
    final row = byId(kind, id);
    if (row == null) throw StateError('Запись не найдена');
    final next = {
      for (final entry in _rows.entries) entry.key: [...entry.value],
    };
    next[kind] = [
      for (final item in next[kind]!)
        if (item.id == id)
          kind.fromJson({...item.toJson(), 'deletedAt': null})
        else
          item,
    ];
    await _commit(next, _nextIds);
  });

  Future<void> _persist(
    Map<EntityKind, List<LibraryEntity>> rows,
    Map<EntityKind, int> nextIds,
  ) => _preferences.setString(
    storageKey,
    jsonEncode({
      'schemaVersion': schemaVersion,
      'data': {
        for (final entry in rows.entries)
          entry.key.name: entry.value.map((row) => row.toJson()).toList(),
      },
      'nextIds': {
        for (final entry in nextIds.entries) entry.key.name: entry.value,
      },
    }),
  );

  Future<void> _commit(
    Map<EntityKind, List<LibraryEntity>> next,
    Map<EntityKind, int> counters,
  ) async {
    await _persist(next, counters);
    _rows = next;
    _nextIds = Map.of(counters);
    notifyListeners();
  }

  void dismissNotice() {
    storageNotice = null;
    notifyListeners();
  }
}
