import 'package:flutter_test/flutter_test.dart';
import 'package:library_web/models/book.dart';
import 'package:library_web/models/reader.dart';
import 'package:library_web/models/catalog_query.dart';
import 'support/mock_api.dart';

void main() {
  group('Разбор моделей ПР4 и ПР6', () {
    test('книга с отсутствующими необязательными полями разбирается', () {
      final book = Book.fromJson({'id': 1});
      expect(book.title, '');
      expect(book.authorIds, isEmpty);
      expect(book.genreIds, isEmpty);
      expect(book.isDeleted, isFalse);
    });
    test('связи книги извлекаются из развёрнутого ответа API', () {
      final book = Book.fromJson({
        'id': 1,
        'title': 'Книга',
        'publisher': {'id': 4, 'name': 'Издательство'},
        'authors': [
          {'id': 2, 'fullName': 'Автор'},
        ],
        'genres': [
          {'id': 3, 'name': 'Жанр'},
        ],
      });
      expect(book.publisherId, 4);
      expect(book.authorIds, [2]);
      expect(book.genreIds, [3]);
    });
    test('книга сохраняет значения при преобразовании в JSON и обратно', () {
      final book = Book.fromJson(bookJson);
      expect(Book.fromJson(book.toJson()).toJson(), book.toJson());
    });
    test('читатель разбирает вложенный билет', () {
      final reader = Reader.fromJson({
        'id': 1,
        'fullName': 'Читатель',
        'card': {
          'id': 2,
          'number': 'RC-000001',
          'issuedAt': '2020-01-01',
          'expiresAt': '2030-01-01',
        },
      });
      expect(reader.card.id, 2);
      expect(reader.card.number, 'RC-000001');
      expect(reader.card.expiresAt, DateTime(2030));
    });
    test('некорректные параметры страниц заменяются допустимыми', () {
      final query = CatalogQuery.fromParams({'page': '-1', 'size': '999'});
      expect(query.page, 1);
      expect(query.size, 10);
    });
    test('поиск, сортировка и фильтры сохраняются в URL', () {
      final query = CatalogQuery.fromParams({
        'page': '2',
        'size': '25',
        'search': 'война',
        'sort': 'year,desc',
        'genreId': '3',
      });
      expect(query.toParams(), {
        'page': '2',
        'size': '25',
        'search': 'война',
        'sort': 'year,desc',
        'genreId': '3',
      });
    });
  });
}
