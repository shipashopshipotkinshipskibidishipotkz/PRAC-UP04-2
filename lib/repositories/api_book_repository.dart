import 'package:dio/dio.dart';
import '../core/api_exceptions.dart';
import '../core/api_client.dart';
import '../core/json_values.dart';
import '../models/book.dart';
import '../models/book_query.dart';
import '../models/catalog_query.dart';
import '../models/entity_kind.dart';
import '../models/page_result.dart';
import 'api_library_repository.dart';
import 'book_repository.dart';

class ApiBookRepository implements BookRepository {
  final ApiLibraryRepository _repository;
  final Dio _dio;
  ApiBookRepository(Dio dio)
    : _dio = dio,
      _repository = ApiLibraryRepository(dio);
  @override
  Future<PageResult<Book>> find(BookQuery query) async {
    final page = await _repository.find(
      EntityKind.books,
      CatalogQuery.fromParams(query.toQueryParams()),
    );
    return PageResult(
      items: page.items.cast<Book>(),
      page: page.page,
      size: page.size,
      total: page.total,
    );
  }

  @override
  Future<Book?> findById(int id) async {
    try {
      return await _repository.findById(EntityKind.books, id) as Book;
    } on NotFoundException {
      return null;
    }
  }

  @override
  Future<Book> create(Book book) async =>
      await _repository.save(EntityKind.books, book.toJson()) as Book;
  @override
  Future<Book> update(Book book) async =>
      await _repository.save(EntityKind.books, book.toJson(), id: book.id)
          as Book;
  @override
  Future<void> softDelete(int id) => _repository.delete(EntityKind.books, [id]);
  @override
  Future<void> hardDelete(int id) =>
      _repository.delete(EntityKind.books, [id], hard: true);
  @override
  Future<void> restore(int id) => _repository.restore(EntityKind.books, id);
  @override
  Future<int> deleteMany(List<int> ids) async {
    return apiGuard(() async {
      final response = await _dio.post<dynamic>(
        '/books/bulk-delete',
        data: {'ids': ids.toSet().toList()},
      );
      return JsonValues.integer(JsonValues.object(response.data)['deleted']);
    });
  }
}
