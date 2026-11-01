import '../core/json_values.dart';

class LibraryCard {
  final int id;
  final String number;
  final DateTime? issuedAt;
  final DateTime? expiresAt;
  const LibraryCard({
    required this.id,
    required this.number,
    this.issuedAt,
    this.expiresAt,
  });
  Map<String, dynamic> toJson() => {
    'id': id,
    'number': number,
    'issuedAt': issuedAt?.toIso8601String(),
    'expiresAt': expiresAt?.toIso8601String(),
  };
  factory LibraryCard.fromJson(Map<String, dynamic> json) => LibraryCard(
    id: JsonValues.integer(json['id']),
    number: JsonValues.text(json['number']),
    issuedAt: JsonValues.date(json['issuedAt']),
    expiresAt: JsonValues.date(json['expiresAt']),
  );
}
