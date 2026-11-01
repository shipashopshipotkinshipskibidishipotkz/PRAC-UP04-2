import '../models/entity_kind.dart';
import 'entity_fields.dart';
import 'json_values.dart';
import 'validators.dart';

Map<String, String> validateInput(EntityKind kind, Map<String, dynamic> data) {
  final errors = <String, String>{};
  for (final field in fieldsFor(kind)) {
    if (kind == EntityKind.books && field.name == 'copiesAvailable') continue;
    final error = field.validator(fieldText(data, field.name));
    if (error != null) errors[field.name] = error;
  }
  if (kind == EntityKind.books) {
    if (JsonValues.integer(data['publisherId']) <= 0) {
      errors['publisherId'] = 'Выберите издательство';
    }
    if (JsonValues.ids(data['authorIds']).isEmpty) {
      errors['authorIds'] = 'Выберите хотя бы одного автора';
    }
    if (JsonValues.ids(data['genreIds']).isEmpty) {
      errors['genreIds'] = 'Выберите хотя бы один жанр';
    }
  }
  if (kind == EntityKind.authors &&
      fieldText(data, 'deathYear').isNotEmpty &&
      JsonValues.integer(data['deathYear']) <
          JsonValues.integer(data['birthYear'])) {
    errors['deathYear'] = 'Год смерти не может быть раньше года рождения';
  }
  if (kind == EntityKind.readers) {
    final issued = V.parseDate(fieldText(data, 'card.issuedAt'));
    final expires = V.parseDate(fieldText(data, 'card.expiresAt'));
    final now = DateTime.now();
    if (issued != null &&
        issued.isAfter(DateTime(now.year, now.month, now.day))) {
      errors['card.issuedAt'] = 'Дата выдачи не может быть в будущем';
    }
    if (issued != null && expires != null && !expires.isAfter(issued)) {
      errors['card.expiresAt'] = 'Срок действия должен быть позже даты выдачи';
    }
  }
  return errors;
}
