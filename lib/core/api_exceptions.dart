sealed class ApiException implements Exception {
  final String message;
  const ApiException(this.message);
  @override
  String toString() => message;
}

class NetworkException extends ApiException {
  const NetworkException([
    super.message =
        'Не удалось соединиться с сервером. Проверьте соединение. Если сервер запущен, проверьте CORS в консоли браузера.',
  ]);
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException([
    super.message = 'Для изменения данных войдите в учебный API.',
  ]);
}

class ForbiddenException extends ApiException {
  const ForbiddenException([
    super.message = 'Недостаточно прав для этого действия.',
  ]);
}

class NotFoundException extends ApiException {
  const NotFoundException([super.message = 'Запись не найдена.']);
}

class ConflictException extends ApiException {
  const ConflictException([
    super.message = 'Операция невозможна из-за связанных данных.',
  ]);
}

class ValidationException extends ApiException {
  final Map<String, String> errors;
  const ValidationException(super.message, this.errors);
}

class ServerException extends ApiException {
  const ServerException([
    super.message = 'Ошибка на сервере. Попробуйте позже.',
  ]);
}

class BadRequestException extends ApiException {
  const BadRequestException([
    super.message = 'Сервер отклонил параметры запроса.',
  ]);
}

class InvalidResponseException extends ApiException {
  const InvalidResponseException([
    super.message = 'Сервер вернул данные в неожиданном формате.',
  ]);
}

class RequestCancelledException extends ApiException {
  const RequestCancelledException() : super('Запрос отменён.');
}

ApiException mapHttpError(int status, Object? body) {
  final message =
      body is Map && body['message'] is String
          ? body['message'] as String
          : null;
  return switch (status) {
    400 => BadRequestException(message ?? 'Сервер отклонил параметры запроса.'),
    401 => UnauthorizedException(
      message ?? 'Для изменения данных войдите в учебный API.',
    ),
    403 => ForbiddenException(
      message ?? 'Недостаточно прав для этого действия.',
    ),
    404 => NotFoundException(message ?? 'Запись не найдена.'),
    409 => ConflictException(
      message ?? 'Операция невозможна из-за связанных данных.',
    ),
    422 => ValidationException(
      message ?? 'Ошибка валидации',
      body is Map && body['errors'] is Map
          ? (body['errors'] as Map).map(
            (key, value) => MapEntry('$key', '$value'),
          )
          : const {},
    ),
    _ => ServerException(
      message ?? 'Ошибка на сервере (код $status). Попробуйте позже.',
    ),
  };
}
