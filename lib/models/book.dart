import '../core/json_values.dart';
import 'library_entity.dart';

class Book implements LibraryEntity {
  @override
  final int id;
  final String title;
  final String isbn;
  final int year;
  final int pages;
  final int publisherId;
  final List<int> authorIds;
  final List<int> genreIds;
  final int copiesTotal;
  final int copiesAvailable;
  @override
  final DateTime? deletedAt;

  const Book({
    required this.id,
    required this.title,
    required this.isbn,
    required this.year,
    required this.pages,
    required this.publisherId,
    required this.authorIds,
    required this.genreIds,
    required this.copiesTotal,
    required this.copiesAvailable,
    this.deletedAt,
  });

  @override
  bool get isDeleted => deletedAt != null;

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'isbn': isbn,
    'year': year,
    'pages': pages,
    'publisherId': publisherId,
    'authorIds': authorIds,
    'genreIds': genreIds,
    'copiesTotal': copiesTotal,
    'copiesAvailable': copiesAvailable,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Book.fromJson(Map<String, dynamic> json) => Book(
    id: JsonValues.integer(json['id']),
    title: JsonValues.text(json['title']),
    isbn: JsonValues.text(json['isbn']),
    year: JsonValues.integer(json['year']),
    pages: JsonValues.integer(json['pages']),
    publisherId: JsonValues.integer(
      json['publisherId'],
      JsonValues.integer(JsonValues.object(json['publisher'])['id']),
    ),
    authorIds: JsonValues.relatedIds(json, 'authorIds', 'authors'),
    genreIds: JsonValues.relatedIds(json, 'genreIds', 'genres'),
    copiesTotal: JsonValues.integer(json['copiesTotal']),
    copiesAvailable: JsonValues.integer(json['copiesAvailable']),
    deletedAt: JsonValues.date(json['deletedAt']),
  );

  Book copyWith({
    String? title,
    String? isbn,
    int? year,
    int? pages,
    int? publisherId,
    List<int>? authorIds,
    List<int>? genreIds,
    int? copiesTotal,
    int? copiesAvailable,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Book(
      id: id,
      title: title ?? this.title,
      isbn: isbn ?? this.isbn,
      year: year ?? this.year,
      pages: pages ?? this.pages,
      publisherId: publisherId ?? this.publisherId,
      authorIds: authorIds ?? this.authorIds,
      genreIds: genreIds ?? this.genreIds,
      copiesTotal: copiesTotal ?? this.copiesTotal,
      copiesAvailable: copiesAvailable ?? this.copiesAvailable,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}
