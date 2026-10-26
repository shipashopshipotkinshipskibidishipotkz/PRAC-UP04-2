class Author {
  final int id;
  final String firstName;
  final String lastName;
  final String country;
  final int birthYear;
  final int? deathYear;
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

  String get fullName => '$firstName $lastName';
  bool get isDeleted => deletedAt != null;

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