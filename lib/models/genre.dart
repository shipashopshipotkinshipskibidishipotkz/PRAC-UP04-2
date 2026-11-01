import '../core/json_values.dart';
import 'library_entity.dart';

class Genre implements LibraryEntity {
  @override
  final int id;
  final String name;
  final String description;
  @override
  final DateTime? deletedAt;
  const Genre({
    required this.id,
    required this.name,
    required this.description,
    this.deletedAt,
  });
  @override
  bool get isDeleted => deletedAt != null;
  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'deletedAt': deletedAt?.toIso8601String(),
  };
  factory Genre.fromJson(Map<String, dynamic> json) => Genre(
    id: JsonValues.integer(json['id']),
    name: JsonValues.text(json['name']),
    description: JsonValues.text(json['description']),
    deletedAt: JsonValues.date(json['deletedAt']),
  );
}
