abstract interface class LibraryEntity {
  int get id;
  DateTime? get deletedAt;
  bool get isDeleted;
  Map<String, dynamic> toJson();
}
