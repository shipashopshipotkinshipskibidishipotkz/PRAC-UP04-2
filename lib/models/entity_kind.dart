import 'author.dart';
import 'book.dart';
import 'genre.dart';
import 'library_entity.dart';
import 'publisher.dart';
import 'reader.dart';

enum EntityKind {
  books('Книги', 'Книга', 'title'),
  authors('Авторы', 'Автор', 'fullName'),
  genres('Жанры', 'Жанр', 'name'),
  publishers('Издательства', 'Издательство', 'name'),
  readers('Читатели', 'Читатель', 'fullName');

  final String label;
  final String singular;
  final String titleField;
  const EntityKind(this.label, this.singular, this.titleField);
  String get path => '/$name';
  String titleOf(LibraryEntity entity) =>
      entity.toJson()[titleField]?.toString() ?? '';
  LibraryEntity fromJson(Map<String, dynamic> json) => switch (this) {
    books => Book.fromJson(json),
    authors => Author.fromJson(json),
    genres => Genre.fromJson(json),
    publishers => Publisher.fromJson(json),
    readers => Reader.fromJson(json),
  };
}
