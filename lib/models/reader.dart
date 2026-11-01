import '../core/json_values.dart';
import 'library_card.dart';
import 'library_entity.dart';

class Reader implements LibraryEntity {
  @override
  final int id;
  final String fullName;
  final String email;
  final String phone;
  final LibraryCard card;
  @override
  final DateTime? deletedAt;
  const Reader({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.card,
    this.deletedAt,
  });
  @override
  bool get isDeleted => deletedAt != null;
  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'email': email,
    'phone': phone,
    'card': card.toJson(),
    'deletedAt': deletedAt?.toIso8601String(),
  };
  factory Reader.fromJson(Map<String, dynamic> json) => Reader(
    id: JsonValues.integer(json['id']),
    fullName: JsonValues.text(json['fullName']),
    email: JsonValues.text(json['email']),
    phone: JsonValues.text(json['phone']),
    card: LibraryCard.fromJson(JsonValues.object(json['card'])),
    deletedAt: JsonValues.date(json['deletedAt']),
  );
}
