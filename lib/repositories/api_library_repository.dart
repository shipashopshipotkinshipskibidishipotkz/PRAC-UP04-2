import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/api_exceptions.dart';
import '../core/input_validation.dart';
import '../core/json_values.dart';
import '../core/request_cancellation.dart';
import '../models/author.dart';
import '../models/catalog_query.dart';
import '../models/entity_kind.dart';
import '../models/library_entity.dart';
import '../models/page_result.dart';
import 'library_repository.dart';

class ApiLibraryRepository extends LibraryRepository {
  final Dio _dio;
  final _references = <EntityKind, List<LibraryEntity>>{};
  final _referenceRequests = <EntityKind, Future<List<LibraryEntity>>>{};
  final _publisherAuthors = <int, Set<int>>{};
  final _publisherRequests = <int, Future<void>>{};
  final _pages = <EntityKind, List<LibraryEntity>>{};
  final _details = <EntityKind, LibraryEntity>{};

  ApiLibraryRepository(this._dio);

  void clearSessionData() {
    _pages.clear();
    _details.clear();
    _references.clear();
    _referenceRequests.clear();
    _publisherAuthors.clear();
    _publisherRequests.clear();
  }

  Map<String, dynamic> _object(Object? value) {
    if (value is! Map) throw const InvalidResponseException();
    return JsonValues.object(value);
  }

  PageResult<LibraryEntity> _parsePage(
    EntityKind kind,
    Object? value,
    int fallbackSize,
  ) {
    final data = _object(value);
    if (data['items'] is! List) throw const InvalidResponseException();
    return PageResult(
      items:
          (data['items'] as List)
              .whereType<Map>()
              .map((json) => kind.fromJson(JsonValues.object(json)))
              .toList(),
      page: JsonValues.integer(data['page'], 1).clamp(1, 1000000).toInt(),
      size:
          JsonValues.integer(data['size'], fallbackSize).clamp(1, 100).toInt(),
      total: JsonValues.integer(data['total']).clamp(0, 100000000).toInt(),
    );
  }

  @override
  Future<PageResult<LibraryEntity>> find(
    EntityKind kind,
    CatalogQuery query, {
    RequestCancellation? cancellation,
  }) => apiGuard(() async {
    final token = CancelToken();
    final detach = cancellation?.onCancel(() => token.cancel('Запрос устарел'));
    try {
      final response = await _dio.get<dynamic>(
        kind.path,
        queryParameters: {
          ...query.toParams(),
          'page': query.page,
          'size': query.size,
          'sort':
              '${query.sortField.isEmpty ? kind.titleField : query.sortField},${query.ascending ? 'asc' : 'desc'}',
        },
        cancelToken: token,
      );
      final result = _parsePage(kind, response.data, query.size);
      if (cancellation?.isCancelled ?? false) {
        throw const RequestCancelledException();
      }
      _pages[kind] = result.items;
      return result;
    } finally {
      detach?.call();
    }
  });

  @override
  Future<LibraryEntity> findById(EntityKind kind, int id) => apiGuard(() async {
    final response = await _dio.get<dynamic>(
      '${kind.path}/$id',
      queryParameters: {'includeDeleted': true},
    );
    final entity = kind.fromJson(_object(response.data));
    _details[kind] = entity;
    return entity;
  });

  Future<List<LibraryEntity>> _loadReference(EntityKind kind) {
    if (_references.containsKey(kind)) return Future.value(_references[kind]!);
    return _referenceRequests.putIfAbsent(
      kind,
      () => apiGuard(() async {
        try {
          final rows = <LibraryEntity>[];
          var page = 1;
          while (true) {
            final response = await _dio.get<dynamic>(
              kind.path,
              queryParameters: {
                'page': page,
                'size': 100,
                'includeDeleted': true,
                'sort': '${kind.titleField},asc',
              },
            );
            final result = _parsePage(kind, response.data, 100);
            rows.addAll(result.items);
            if (!result.hasNext) break;
            page++;
          }
          _references[kind] = List.unmodifiable(rows);
          return rows;
        } finally {
          _referenceRequests.remove(kind);
        }
      }),
    );
  }

  @override
  Future<void> loadReferences() async {
    await Future.wait([
      for (final kind in [
        EntityKind.authors,
        EntityKind.genres,
        EntityKind.publishers,
      ])
        _loadReference(kind),
    ]);
  }

  @override
  Future<void> loadAuthorsForPublisher(int? publisherId) async {
    if (publisherId == null || _publisherAuthors.containsKey(publisherId)) {
      return;
    }
    return _publisherRequests.putIfAbsent(
      publisherId,
      () => apiGuard(() async {
        try {
          final ids = <int>{};
          var page = 1;
          while (true) {
            final response = await _dio.get<dynamic>(
              '/authors',
              queryParameters: {
                'publisherId': publisherId,
                'page': page,
                'size': 100,
              },
            );
            final result = _parsePage(EntityKind.authors, response.data, 100);
            ids.addAll(result.items.map((row) => row.id));
            if (!result.hasNext) break;
            page++;
          }
          _publisherAuthors[publisherId] = ids;
        } finally {
          _publisherRequests.remove(publisherId);
        }
      }),
    );
  }

  @override
  List<LibraryEntity> all(EntityKind kind, {bool includeDeleted = false}) =>
      List.unmodifiable(
        (_references[kind] ?? _pages[kind] ?? []).where(
          (row) => includeDeleted || !row.isDeleted,
        ),
      );
  @override
  LibraryEntity? byId(EntityKind kind, int id) {
    if (_details[kind]?.id == id) return _details[kind];
    for (final row in all(kind, includeDeleted: true)) {
      if (row.id == id) return row;
    }
    return null;
  }

  @override
  String title(EntityKind kind, int id) {
    final row = byId(kind, id);
    return row == null
        ? 'Запись #$id'
        : '${kind.titleOf(row)}${row.isDeleted ? ' (в корзине)' : ''}';
  }

  @override
  List<Author> authorsForPublisher(int? publisherId) =>
      publisherId == null
          ? []
          : authors
              .where(
                (row) =>
                    _publisherAuthors[publisherId]?.contains(row.id) ?? true,
              )
              .toList();
  @override
  Map<String, String> validate(
    EntityKind kind,
    Map<String, dynamic> data, {
    int? id,
  }) => validateInput(kind, data);

  void _changed(EntityKind kind) {
    _pages.remove(kind);
    _details.remove(kind);
    _references.remove(kind);
    _referenceRequests.remove(kind);
    if (kind == EntityKind.books || kind == EntityKind.authors) {
      _publisherAuthors.clear();
      _publisherRequests.clear();
    }
    notifyListeners();
  }

  Map<String, dynamic> _input(EntityKind kind, Map<String, dynamic> data) {
    final input =
        {...data}
          ..remove('id')
          ..remove('deletedAt')
          ..remove('createdAt');
    if (kind == EntityKind.books) input.remove('copiesAvailable');
    return input;
  }

  @override
  Future<LibraryEntity> save(
    EntityKind kind,
    Map<String, dynamic> data, {
    int? id,
  }) => apiGuard(() async {
    final errors = validate(kind, data, id: id);
    if (errors.isNotEmpty) {
      throw ValidationException('Проверьте поля формы', errors);
    }
    final response =
        id == null
            ? await _dio.post<dynamic>(kind.path, data: _input(kind, data))
            : await _dio.put<dynamic>(
              '${kind.path}/$id',
              data: _input(kind, data),
            );
    final entity = kind.fromJson(_object(response.data));
    _changed(kind);
    return entity;
  });
  @override
  Future<void> delete(
    EntityKind kind,
    Iterable<int> ids, {
    bool hard = false,
  }) => apiGuard(() async {
    final selected = ids.toSet().toList();
    if (selected.isEmpty) return;
    if (!hard && selected.length > 1) {
      await _dio.post<dynamic>(
        '${kind.path}/bulk-delete',
        data: {'ids': selected},
      );
    } else {
      for (final id in selected) {
        await _dio.delete<dynamic>(
          '${kind.path}/$id',
          queryParameters: {if (hard) 'hard': true},
        );
      }
    }
    _changed(kind);
  });
  @override
  Future<void> restore(EntityKind kind, int id) => apiGuard(() async {
    await _dio.post<dynamic>('${kind.path}/$id/restore');
    _changed(kind);
  });
  @override
  Future<PageResult<LibraryEntity>> relatedBooks(
    EntityKind kind,
    int id,
    int page, {
    int size = 10,
  }) => find(
    EntityKind.books,
    CatalogQuery(
      page: page,
      size: size,
      includeDeleted: true,
      filters: {
        switch (kind) {
          EntityKind.authors => 'authorId',
          EntityKind.genres => 'genreId',
          _ => 'publisherId',
        }: '$id',
      },
    ),
  );
  @override
  Future<void> createLoan({
    required int bookId,
    required int readerId,
    required int days,
  }) => apiGuard(() async {
    await _dio.post<dynamic>(
      '/loans',
      data: {'bookId': bookId, 'readerId': readerId, 'days': days},
    );
    _changed(EntityKind.books);
  });
  @override
  void dispose() {
    _dio.close(force: true);
    super.dispose();
  }
}
