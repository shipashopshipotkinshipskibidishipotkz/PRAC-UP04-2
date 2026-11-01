abstract final class JsonValues {
  static String text(Object? value, [String fallback = '']) =>
      value is String ? value : fallback;

  static int integer(Object? value, [int fallback = 0]) =>
      optionalInteger(value) ?? fallback;

  static int? optionalInteger(Object? value) {
    if (value is int) return value;
    if (value is num && value.isFinite && value == value.roundToDouble()) {
      return value.toInt();
    }
    return value is String ? int.tryParse(value) : null;
  }

  static DateTime? date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  static Map<String, dynamic> object(Object? value) =>
      value is Map
          ? value.map((key, value) => MapEntry(key.toString(), value))
          : <String, dynamic>{};

  static List<int> ids(Object? value) =>
      value is List
          ? value
              .map(optionalInteger)
              .whereType<int>()
              .where((id) => id > 0)
              .toSet()
              .toList()
          : <int>[];

  static List<int> relatedIds(
    Map<String, dynamic> json,
    String idsKey,
    String objectsKey,
  ) {
    if (json[idsKey] is List) return ids(json[idsKey]);
    final objects = json[objectsKey];
    return objects is List
        ? ids(objects.map((e) => object(e)['id']).toList())
        : <int>[];
  }
}
