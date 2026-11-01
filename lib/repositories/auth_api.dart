import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/api_exceptions.dart';
import '../models/app_user.dart';

class AuthResult {
  final String accessToken;
  final String refreshToken;
  final AppUser user;
  AuthResult.fromJson(Map<String, dynamic> json)
    : accessToken = json['accessToken'] as String,
      refreshToken = json['refreshToken'] as String,
      user = AppUser.fromJson(Map<String, dynamic>.from(json['user'] as Map)) {
    if (accessToken.isEmpty || refreshToken.isEmpty) {
      throw const InvalidResponseException();
    }
  }
}

class AuthApi {
  final Dio dio;
  AuthApi(this.dio);
  Future<AuthResult> login(String username, String password) =>
      apiGuard(() async {
        final r = await dio.post<Map<String, dynamic>>(
          '/auth/login',
          data: {'username': username.trim(), 'password': password},
        );
        return AuthResult.fromJson(r.data!);
      });
  Future<void> register(Map<String, String> data) => apiGuard(() async {
    await dio.post<dynamic>('/auth/register', data: data);
  });
  Future<AuthResult> refresh(String token) => apiGuard(() async {
    final r = await dio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refreshToken': token},
    );
    return AuthResult.fromJson(r.data!);
  });
  Future<AppUser> me(String access) => apiGuard(() async {
    final r = await dio.get<Map<String, dynamic>>(
      '/auth/me',
      options: Options(headers: {'Authorization': 'Bearer $access'}),
    );
    return AppUser.fromJson(r.data!);
  });
  Future<void> logout(String refresh) => apiGuard(() async {
    await dio.post<dynamic>('/auth/logout', data: {'refreshToken': refresh});
  });
}
