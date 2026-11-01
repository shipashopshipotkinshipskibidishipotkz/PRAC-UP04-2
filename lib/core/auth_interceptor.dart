import 'package:dio/dio.dart';
import '../state/auth_notifier.dart';
import 'api_exceptions.dart';

void attachAuthentication(Dio dio, AuthNotifier auth) {
  dio.interceptors.insert(
    1,
    InterceptorsWrapper(
      onRequest: (options, handler) {
        options.extra.putIfAbsent('authSession', () => auth.sessionEpoch);
        if (options.extra['authSession'] != auth.sessionEpoch) {
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.cancel,
              error: const RequestCancelledException(),
            ),
          );
          return;
        }
        final token = auth.accessToken;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        } else {
          options.headers.remove('Authorization');
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        if (response.requestOptions.extra['authSession'] != auth.sessionEpoch) {
          handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              type: DioExceptionType.cancel,
              error: const RequestCancelledException(),
            ),
          );
        } else {
          handler.next(response);
        }
      },
      onError: (error, handler) async {
        final options = error.requestOptions;
        if (options.extra['authSession'] != auth.sessionEpoch) {
          handler.next(
            DioException(
              requestOptions: options,
              type: DioExceptionType.cancel,
              error: const RequestCancelledException(),
            ),
          );
          return;
        }
        if (error.response?.statusCode != 401 ||
            options.path.startsWith('/auth/') ||
            options.extra['authRetried'] == true ||
            auth.accessToken == null) {
          if (error.response?.statusCode == 401 &&
              options.extra['authRetried'] == true) {
            await auth.logout(reason: 'Сессия недействительна. Войдите снова.');
          }
          handler.next(error);
          return;
        }
        try {
          if (options.headers['Authorization'] ==
              'Bearer ${auth.accessToken}') {
            await auth.refreshTokens();
          }
          if (auth.accessToken == null) {
            handler.next(error);
            return;
          }
          final response = await dio.fetch<dynamic>(
            options.copyWith(
              headers: {
                ...options.headers,
                'Authorization': 'Bearer ${auth.accessToken}',
              },
              extra: {...options.extra, 'authRetried': true},
            ),
          );
          handler.resolve(response);
        } on DioException catch (retryError) {
          handler.next(retryError);
        } catch (_) {
          handler.next(error);
        }
      },
    ),
  );
}
