import '../core/json_values.dart';
import 'library_entity.dart';

class Publisher implements LibraryEntity {
  @override
  final int id;
  final String name;
  final String city;
  final int foundedYear;
  @override
  final DateTime? deletedAt;
  const Publisher({
    required this.id,
    required this.name,
    required this.city,
    required this.foundedYear,
    this.deletedAt,
  });
  @override
  bool get isDeleted => deletedAt != null;
  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'city': city,
    'foundedYear': foundedYear,
    'deletedAt': deletedAt?.toIso8601String(),
  };
  factory Publisher.fromJson(Map<String, dynamic> json) => Publisher(
    id: JsonValues.integer(json['id']),
    name: JsonValues.text(json['name']),
    city: JsonValues.text(json['city']),
    foundedYear: JsonValues.integer(json['foundedYear']),
    deletedAt: JsonValues.date(json['deletedAt']),
  );
}
