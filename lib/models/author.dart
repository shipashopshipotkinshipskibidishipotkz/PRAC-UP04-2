import '../core/json_values.dart';
import 'library_entity.dart';

class Author implements LibraryEntity {
  @override
  final int id;
  final String firstName;
  final String lastName;
  final String country;
  final int birthYear;
  final int? deathYear;
  @override
  final DateTime? deletedAt;

  const Author({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.country,
    required this.birthYear,
    this.deathYear,
    this.deletedAt,
  });

  String get fullName => '$firstName $lastName'.trim();
  @override
  bool get isDeleted => deletedAt != null;

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'country': country,
    'birthYear': birthYear,
    'deathYear': deathYear,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Author.fromJson(Map<String, dynamic> json) => Author(
    id: JsonValues.integer(json['id']),
    firstName:
        json['fullName'] is String
            ? JsonValues.text(json['fullName'])
            : JsonValues.text(json['firstName']),
    lastName:
        json['fullName'] is String ? '' : JsonValues.text(json['lastName']),
    country: JsonValues.text(json['country']),
    birthYear: JsonValues.integer(json['birthYear']),
    deathYear: JsonValues.optionalInteger(json['deathYear']),
    deletedAt: JsonValues.date(json['deletedAt']),
  );

  Author copyWith({
    String? firstName,
    String? lastName,
    String? country,
    int? birthYear,
    int? deathYear,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Author(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      country: country ?? this.country,
      birthYear: birthYear ?? this.birthYear,
      deathYear: deathYear ?? this.deathYear,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}
