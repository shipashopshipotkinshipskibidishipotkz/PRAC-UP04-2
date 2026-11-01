import 'package:flutter_test/flutter_test.dart';
import 'package:library_web/core/validators.dart';
import 'package:library_web/core/input_validation.dart';
import 'package:library_web/models/entity_kind.dart';

void main() {
  group('Валидаторы ПР3 и ПР6', () {
    test('обязательное поле отклоняет null, пустую строку и пробелы', () {
      for (final value in [null, '', '   ']) {
        expect(V.required()(value), isNotNull);
      }
      expect(V.required()('Книга'), isNull);
    });
    test('длина текста проверяется после удаления пробелов по краям', () {
      final validate = V.text(min: 2, max: 5);
      expect(validate(' а '), isNotNull);
      expect(validate(' аб '), isNull);
      expect(validate('abcdef'), isNotNull);
    });
    test('год должен быть целым числом в заданных границах', () {
      final validate = V.integer(min: 1400, max: 2026);
      for (final value in ['1399', '2027', '2020.5', 'год']) {
        expect(validate(value), isNotNull);
      }
      expect(validate('1400'), isNull);
      expect(validate('2026'), isNull);
    });
    test('необязательное число допускает пустое значение', () {
      expect(V.integer(optional: true)(''), isNull);
      expect(V.integer(optional: false)(''), isNotNull);
    });
    test('ISBN нормализуется и проверяется по формату', () {
      expect(V.normalizeIsbn(' 0-306-40615-x '), '030640615X');
      expect(V.isbn('978-5-17-118366-4'), isNull);
      expect(V.isbn('0-306-40615-X'), isNull);
      expect(V.isbn('123'), isNotNull);
    });
    test('почта проверяется на наличие домена и отсутствие пробелов', () {
      expect(V.email('reader@example.org'), isNull);
      expect(V.email('reader@example'), isNotNull);
      expect(V.email('reader name@example.org'), isNotNull);
    });
    test('телефон допускает оформление, но проверяет количество цифр', () {
      expect(V.phone('+7 (999) 123-45-67'), isNull);
      expect(V.phone('123'), isNotNull);
      expect(V.phone('+7999text1234567'), isNotNull);
    });
    test('несуществующая дата не превращается в дату следующего месяца', () {
      expect(V.parseDate('2024-02-29'), DateTime(2024, 2, 29));
      expect(V.parseDate('2025-02-29'), isNull);
      expect(V.parseDate('2026-04-31'), isNull);
    });
    test('дата окончания билета должна быть позже даты выдачи', () {
      final errors = validateInput(EntityKind.readers, {
        'fullName': 'Тестовый читатель',
        'email': 'reader@example.org',
        'phone': '+79991234567',
        'card': {
          'number': 'RC-000001',
          'issuedAt': '2020-01-02',
          'expiresAt': '2020-01-01',
        },
      });
      expect(errors, contains('card.expiresAt'));
    });
  });
}
