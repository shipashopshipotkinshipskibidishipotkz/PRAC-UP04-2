import '../models/entity_kind.dart';
import 'validators.dart';

class EntityField {
  final String name;
  final String label;
  final Validator validator;
  final bool numeric;
  final int lines;
  final String? hint;
  const EntityField(
    this.name,
    this.label,
    this.validator, {
    this.numeric = false,
    this.lines = 1,
    this.hint,
  });
}

List<EntityField> fieldsFor(EntityKind kind) {
  final year = DateTime.now().year;
  return switch (kind) {
    EntityKind.books => [
      EntityField('title', 'Название', V.text(max: 200)),
      const EntityField('isbn', 'ISBN', V.isbn, hint: '978-5-17-000001-1'),
      EntityField(
        'year',
        'Год издания',
        V.integer(min: 1450, max: year),
        numeric: true,
      ),
      EntityField('pages', 'Страниц', V.integer(min: 1), numeric: true),
      EntityField(
        'copiesTotal',
        'Всего экземпляров',
        V.integer(min: 1, max: 10000),
        numeric: true,
      ),
      EntityField(
        'copiesAvailable',
        'Доступно экземпляров',
        V.integer(max: 10000),
        numeric: true,
      ),
    ],
    EntityKind.authors => [
      EntityField('fullName', 'ФИО автора', V.text()),
      EntityField('country', 'Страна', V.text(max: 100)),
      EntityField(
        'birthYear',
        'Год рождения',
        V.integer(min: 1, max: year),
        numeric: true,
      ),
      EntityField(
        'deathYear',
        'Год смерти (необязательно)',
        V.integer(min: 1, max: year, optional: true),
        numeric: true,
      ),
    ],
    EntityKind.genres => [
      EntityField('name', 'Название жанра', V.text(max: 100)),
      EntityField(
        'description',
        'Описание',
        V.text(min: 1, max: 1000),
        lines: 3,
      ),
    ],
    EntityKind.publishers => [
      EntityField('name', 'Название издательства', V.text()),
      EntityField('city', 'Город', V.text(max: 100)),
      EntityField(
        'foundedYear',
        'Год основания',
        V.integer(min: 1400, max: year),
        numeric: true,
      ),
    ],
    EntityKind.readers => [
      EntityField('fullName', 'ФИО читателя', V.text()),
      const EntityField('email', 'Электронная почта', V.email),
      const EntityField('phone', 'Телефон', V.phone, hint: '+7 900 000-00-00'),
      const EntityField(
        'card.number',
        'Номер билета',
        V.cardNumber,
        hint: 'RC-000001',
      ),
      const EntityField(
        'card.issuedAt',
        'Дата выдачи',
        V.date,
        hint: 'ГГГГ-ММ-ДД',
      ),
      const EntityField(
        'card.expiresAt',
        'Действителен до',
        V.date,
        hint: 'ГГГГ-ММ-ДД',
      ),
    ],
  };
}

Object? fieldValue(Map<String, dynamic> data, String name) {
  if (!name.contains('.')) return data[name];
  final parts = name.split('.');
  final nested = data[parts.first];
  return nested is Map ? nested[parts.last] : null;
}

String fieldText(Map<String, dynamic> data, String name) {
  final value = fieldValue(data, name);
  if (value == null) return '';
  final text = value.toString();
  return name.endsWith('At') && text.length >= 10
      ? text.substring(0, 10)
      : text;
}
