import 'package:flutter/foundation.dart';
import '../core/request_cancellation.dart';
import '../models/author.dart';
import '../models/book.dart';
import '../models/catalog_query.dart';
import '../models/entity_kind.dart';
import '../models/genre.dart';
import '../models/library_entity.dart';
import '../models/page_result.dart';
import '../models/publisher.dart';

abstract class LibraryRepository extends ChangeNotifier {
  bool get isAuthenticated;
  String? get accountName;
  Future<void> signIn(String username, String password);
  void signOut();
  Future<PageResult<LibraryEntity>> find(
    EntityKind kind,
    CatalogQuery query, {
    RequestCancellation? cancellation,
  });
  Future<LibraryEntity> findById(EntityKind kind, int id);
  Future<void> loadReferences();
  Future<void> loadAuthorsForPublisher(int? publisherId);
  List<LibraryEntity> all(EntityKind kind, {bool includeDeleted = false});
  LibraryEntity? byId(EntityKind kind, int id);
  String title(EntityKind kind, int id);
  List<Author> authorsForPublisher(int? publisherId);
  List<Author> get authors => all(EntityKind.authors).cast<Author>();
  List<Genre> get genreList => all(EntityKind.genres).cast<Genre>();
  List<Publisher> get publisherList =>
      all(EntityKind.publishers).cast<Publisher>();
  Map<String, String> validate(
    EntityKind kind,
    Map<String, dynamic> data, {
    int? id,
  });
  Future<LibraryEntity> save(
    EntityKind kind,
    Map<String, dynamic> data, {
    int? id,
  });
  Future<void> delete(EntityKind kind, Iterable<int> ids, {bool hard = false});
  Future<void> restore(EntityKind kind, int id);
  Future<PageResult<LibraryEntity>> relatedBooks(
    EntityKind kind,
    int id,
    int page, {
    int size = 10,
  });
  Future<void> createLoan({
    required int bookId,
    required int readerId,
    required int days,
  });
  Future<Book> refreshBook(int id) async =>
      await findById(EntityKind.books, id) as Book;
}
