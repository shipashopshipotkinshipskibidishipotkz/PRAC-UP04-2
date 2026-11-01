import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:library_web/core/api_client.dart';

typedef MockResponse = (int, Object?);
typedef MockHandler = FutureOr<MockResponse> Function(RequestOptions request);

class MockApiAdapter implements HttpClientAdapter {
  MockHandler respond;
  final requests = <RequestOptions>[];

  MockApiAdapter([this.respond = catalogResponse]);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final (status, data) = await respond(options);
    return ResponseBody.fromString(
      status == 204 ? '' : jsonEncode(data),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio mockDio(MockApiAdapter adapter) => buildDio(
  baseUrl: 'https://library.example/api',
  retryDelay: Duration.zero,
  logger: (_) {},
)..httpClientAdapter = adapter;

const bookJson = <String, dynamic>{
  'id': 1,
  'title': 'Война и мир',
  'isbn': '978-5-17-118366-4',
  'year': 1869,
  'pages': 1300,
  'publisherId': 1,
  'authorIds': [1],
  'genreIds': [1],
  'copiesTotal': 4,
  'copiesAvailable': 3,
};

Map<String, dynamic> pageJson(
  List<Map<String, dynamic>> items, {
  int page = 1,
  int size = 10,
  int? total,
}) => {
  'items': items,
  'page': page,
  'size': size,
  'total': total ?? items.length,
};

MockResponse catalogResponse(RequestOptions request) {
  final records = <String, List<Map<String, dynamic>>>{
    '/books': [bookJson],
    '/authors': [
      {
        'id': 1,
        'fullName': 'Толстой Л. Н.',
        'country': 'Россия',
        'birthYear': 1828,
      },
    ],
    '/genres': [
      {'id': 1, 'name': 'Роман', 'description': 'Литературный жанр'},
    ],
    '/publishers': [
      {'id': 1, 'name': 'АСТ', 'city': 'Москва', 'foundedYear': 1990},
    ],
    '/readers': [
      {
        'id': 1,
        'fullName': 'Тестовый читатель',
        'email': 'reader@example.org',
        'phone': '+79991234567',
        'card': null,
      },
    ],
    '/users': [
      {
        'id': 1,
        'username': 'admin',
        'fullName': 'Администратор',
        'role': 'admin',
      },
      {'id': 2, 'username': 'reader', 'fullName': 'Читатель', 'role': 'reader'},
    ],
    '/loans': [
      {
        'id': 1,
        'reader': {'id': 1, 'fullName': 'Тестовый читатель'},
        'book': {'id': 1, 'title': 'Война и мир'},
        'issuedAt': '2026-11-01T10:00:00Z',
        'dueAt': '2026-12-01T10:00:00Z',
        'returnedAt': null,
        'status': 'active',
      },
    ],
  };
  if (request.path == '/statistics') {
    return (
      200,
      {
        'books': 20,
        'copies': 60,
        'available': 52,
        'readers': 8,
        'activeLoans': 8,
        'overdueLoans': 2,
        'users': 3,
      },
    );
  }
  if (request.path.endsWith('/1')) {
    final collection = request.path.substring(0, request.path.length - 2);
    if (records.containsKey(collection)) {
      return (200, records[collection]!.first);
    }
  }
  return (
    200,
    pageJson(
      records[request.path] ?? [],
      size: request.queryParameters['size'] as int? ?? 10,
    ),
  );
}
