import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_web/core/api_exceptions.dart';
import 'package:library_web/models/book.dart';
import 'package:library_web/models/catalog_query.dart';
import 'package:library_web/models/entity_kind.dart';
import 'package:library_web/repositories/api_library_repository.dart';
import 'support/mock_api.dart';

void main() {
  late MockApiAdapter adapter;
  late ApiLibraryRepository repository;

  setUp(() {
    adapter = MockApiAdapter();
    repository = ApiLibraryRepository(mockDio(adapter));
  });
  tearDown(() => repository.dispose());

  group('Репозиторий с подменённым Dio — ПР4', () {
    test(
      'список разбирает развёрнутые связи и постраничную оболочку',
      () async {
        adapter.respond =
            (_) => (
              200,
              pageJson(
                [
                  {
                    'id': 7,
                    'title': 'Книга',
                    'publisher': {'id': 2},
                    'authors': [
                      {'id': 3},
                    ],
                    'genres': [
                      {'id': 4},
                    ],
                  },
                ],
                page: 2,
                total: 20,
              ),
            );
        final result = await repository.find(
          EntityKind.books,
          const CatalogQuery(page: 2),
        );
        final book = result.items.single as Book;
        expect(result.page, 2);
        expect(result.total, 20);
        expect(book.publisherId, 2);
        expect(book.authorIds, [3]);
        expect(book.genreIds, [4]);
      },
    );
    test(
      'поиск, фильтры, сортировка и страница отправляются серверу',
      () async {
        await repository.find(
          EntityKind.books,
          const CatalogQuery(
            search: 'война',
            page: 2,
            size: 25,
            sortField: 'year',
            ascending: false,
            filters: {'genreId': '3'},
          ),
        );
        final request = adapter.requests.single;
        expect(request.path, '/books');
        expect(request.queryParameters, containsPair('search', 'война'));
        expect(request.queryParameters, containsPair('genreId', '3'));
        expect(request.queryParameters, containsPair('sort', 'year,desc'));
        expect(request.queryParameters, containsPair('page', 2));
        expect(request.queryParameters, containsPair('size', 25));
      },
    );
    test(
      'ответ 422 возвращает карту ошибок полей и не повторяет запись',
      () async {
        adapter.respond =
            (_) => (
              422,
              {
                'message': 'Ошибка валидации',
                'errors': {'isbn': 'Книга с таким ISBN уже существует'},
              },
            );
        await expectLater(
          repository.save(EntityKind.books, bookJson),
          throwsA(
            isA<ValidationException>().having((e) => e.errors, 'errors', {
              'isbn': 'Книга с таким ISBN уже существует',
            }),
          ),
        );
        expect(adapter.requests.length, 1);
        expect(adapter.requests.single.method, 'POST');
      },
    );
    test(
      'недоступный сервер превращается в NetworkException после трёх GET',
      () async {
        adapter.respond =
            (request) =>
                throw DioException(
                  requestOptions: request,
                  type: DioExceptionType.connectionError,
                );
        await expectLater(
          repository.find(EntityKind.books, const CatalogQuery()),
          throwsA(isA<NetworkException>()),
        );
        expect(adapter.requests.length, 3);
        expect(
          adapter.requests.every((request) => request.method == 'GET'),
          isTrue,
        );
      },
    );
    test('чтение восстанавливается после временного ответа 500', () async {
      var attempts = 0;
      adapter.respond =
          (request) =>
              ++attempts < 3
                  ? (500, {'message': 'Временная ошибка'})
                  : catalogResponse(request);
      final result = await repository.find(
        EntityKind.books,
        const CatalogQuery(),
      );
      expect(result.items.single.id, 1);
      expect(attempts, 3);
    });
    test('запись не повторяется при сетевом сбое', () async {
      adapter.respond =
          (request) =>
              throw DioException(
                requestOptions: request,
                type: DioExceptionType.connectionError,
              );
      await expectLater(
        repository.save(EntityKind.books, bookJson),
        throwsA(isA<NetworkException>()),
      );
      expect(adapter.requests.length, 1);
    });
    test(
      '401, 403, 404 и 409 становятся исключениями предметной области',
      () async {
        for (final entry in <(int, Type)>[
          (401, UnauthorizedException),
          (403, ForbiddenException),
          (404, NotFoundException),
          (409, ConflictException),
        ]) {
          adapter.requests.clear();
          adapter.respond = (_) => (entry.$1, {'message': 'Ошибка API'});
          await expectLater(
            repository.findById(EntityKind.books, 1),
            throwsA(
              predicate<Object>((error) => error.runtimeType == entry.$2),
            ),
          );
          expect(adapter.requests.length, 1);
        }
      },
    );
    test('справочники повторно берутся из кэша', () async {
      await repository.loadReferences();
      await repository.loadReferences();
      expect(adapter.requests.map((request) => request.path).toSet(), {
        '/authors',
        '/genres',
        '/publishers',
      });
      expect(adapter.requests.length, 3);
    });
    test(
      'серверное поле copiesAvailable не отправляется при сохранении',
      () async {
        adapter.respond = (_) => (201, bookJson);
        final saved = await repository.save(EntityKind.books, bookJson);
        expect(saved.id, 1);
        final body = adapter.requests.single.data as Map;
        expect(body, isNot(contains('copiesAvailable')));
        expect(body['authorIds'], [1]);
      },
    );
    test('неверная оболочка списка отклоняется понятным исключением', () async {
      adapter.respond = (_) => (200, {'items': 'incorrect'});
      await expectLater(
        repository.find(EntityKind.books, const CatalogQuery()),
        throwsA(isA<InvalidResponseException>()),
      );
    });
  });
}
