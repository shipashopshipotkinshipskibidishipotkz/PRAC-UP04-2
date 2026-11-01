import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_exceptions.dart';
import 'config.dart';

ApiException mapDioError(DioException error) {
  if (error.type == DioExceptionType.cancel) {
    return const RequestCancelledException();
  }
  if (error.error is ApiException) return error.error as ApiException;
  if (error.error is FormatException || error.error is TypeError) {
    return const InvalidResponseException();
  }
  if (error.response?.statusCode != null) {
    return mapHttpError(error.response!.statusCode!, error.response!.data);
  }
  return switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout => const NetworkException(
      'Сервер не ответил вовремя. Попробуйте повторить запрос.',
    ),
    DioExceptionType.connectionError => const NetworkException(),
    DioExceptionType.badCertificate => const NetworkException(
      'Не удалось проверить сертификат сервера.',
    ),
    _ => const NetworkException(),
  };
}

Future<T> apiGuard<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on DioException catch (error) {
    throw mapDioError(error);
  } on FormatException {
    throw const InvalidResponseException();
  } on TypeError {
    throw const InvalidResponseException();
  }
}

Dio buildDio({
  String baseUrl = apiBaseUrl,
  String? Function()? tokenProvider,
  Duration retryDelay = const Duration(milliseconds: 350),
  void Function(String)? logger,
}) {
  void log(String message) {
    if (logger != null) {
      logger(message);
    } else if (kDebugMode) {
      debugPrint(message);
    }
  }

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl.replaceAll(RegExp(r'/+$'), ''),
      connectTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      contentType: Headers.jsonContentType,
      validateStatus: (status) => status != null && status < 500,
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = tokenProvider?.call();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        log('[API] ${options.method} ${options.uri}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        log(
          '[API] ${response.requestOptions.method} ${response.requestOptions.uri} → ${response.statusCode}',
        );
        final status = response.statusCode ?? 0;
        if (status >= 400) {
          handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.badResponse,
              error: mapHttpError(status, response.data),
            ),
            true,
          );
        } else {
          handler.next(response);
        }
      },
      onError: (error, handler) {
        log(
          '[API] ${error.requestOptions.method} ${error.requestOptions.uri} → ${error.response?.statusCode ?? error.type.name}',
        );
        handler.next(error.copyWith(error: mapDioError(error)));
      },
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onError: (error, handler) async {
        final options = error.requestOptions;
        final attempt = options.extra['readAttempt'] as int? ?? 0;
        final mapped = mapDioError(error);
        final retryable =
            mapped is NetworkException ||
            (mapped is ServerException &&
                (error.response?.statusCode ?? 0) >= 500);
        if (options.method != 'GET' ||
            !retryable ||
            attempt >= 2 ||
            (options.cancelToken?.isCancelled ?? false)) {
          handler.next(error);
          return;
        }
        final cancelled = await Future.any<bool>([
          Future.delayed(retryDelay * (1 << attempt), () => false),
          if (options.cancelToken != null)
            options.cancelToken!.whenCancel.then((_) => true),
        ]);
        if (cancelled || (options.cancelToken?.isCancelled ?? false)) {
          handler.next(options.cancelToken!.cancelError!);
          return;
        }
        try {
          final response = await dio.fetch<dynamic>(
            options.copyWith(
              extra: {...options.extra, 'readAttempt': attempt + 1},
            ),
          );
          handler.resolve(response);
        } on DioException catch (lastError) {
          handler.next(lastError);
        }
      },
    ),
  );
  return dio;
}
