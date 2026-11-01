typedef Validator = String? Function(String? value);

abstract final class V {
  static Validator required([String message = 'Поле обязательно']) =>
      (value) => (value?.trim().isEmpty ?? true) ? message : null;

  static Validator length({int min = 0, int max = 255}) => (value) {
    final length = (value ?? '').trim().length;
    if (length < min) return 'Не короче $min символов';
    if (length > max) return 'Не длиннее $max символов';
    return null;
  };

  static Validator text({int min = 2, int max = 150}) =>
      combine([required(), length(min: min, max: max)]);

  static Validator integer({
    int min = 0,
    int max = 100000,
    bool optional = false,
  }) => (value) {
    final text = value?.trim() ?? '';
    if (optional && text.isEmpty) return null;
    if (text.isEmpty) return 'Поле обязательно';
    final number = int.tryParse(text);
    if (number == null) return 'Введите целое число';
    if (number < min || number > max) return 'Допустимо от $min до $max';
    return null;
  };

  static String normalizeIsbn(String value) =>
      value.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();
  static String? isbn(String? value) {
    if (value == null || value.trim().isEmpty) return 'Укажите ISBN';
    return RegExp(r'^(\d{13}|\d{9}[\dX])$').hasMatch(normalizeIsbn(value))
        ? null
        : 'ISBN: 13 цифр или 10 знаков; дефисы допустимы';
  }

  static String? email(String? value) {
    final error = text(min: 5, max: 254)(value);
    if (error != null) return error;
    return RegExp(r'^[^\s@]+@[^\s@.]+(?:\.[^\s@.]+)+$').hasMatch(value!.trim())
        ? null
        : 'Некорректный адрес почты';
  }

  static String? phone(String? value) {
    final text = value?.trim() ?? '';
    final digits = text.replaceAll(RegExp(r'\D'), '');
    return RegExp(r'^\+?[\d ()-]+$').hasMatch(text) &&
            text.length <= 30 &&
            digits.length >= 7 &&
            digits.length <= 15
        ? null
        : 'Телефон: от 7 до 15 цифр, допустимы +, пробелы, скобки и дефисы';
  }

  static String? cardNumber(String? value) =>
      RegExp(r'^RC-\d{6}$').hasMatch(value?.trim().toUpperCase() ?? '')
          ? null
          : 'Номер в формате RC-000001';

  static DateTime? parseDate(String? value) {
    final text = value?.trim() ?? '';
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text)) return null;
    final date = DateTime.tryParse(text);
    if (date == null || date.toIso8601String().substring(0, 10) != text) {
      return null;
    }
    return date;
  }

  static String? date(String? value) {
    final date = parseDate(value);
    return date != null && date.year >= 1900 && date.year <= 2100
        ? null
        : 'Укажите существующую дату: ГГГГ-ММ-ДД (1900–2100)';
  }

  static Validator combine(List<Validator> validators) => (value) {
    for (final validator in validators) {
      final error = validator(value);
      if (error != null) return error;
    }
    return null;
  };
}
