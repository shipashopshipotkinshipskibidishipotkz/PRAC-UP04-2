import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/page_result.dart';
import '../models/app_user.dart';

class AccountRepository {
  final Dio dio;
  AccountRepository(this.dio);
  Future<PageResult<Map<String, dynamic>>> list(
    String path, {
    int page = 1,
    int size = 10,
    String? status,
    String search = '',
  }) => apiGuard(() async {
    final response = await dio.get<Map<String, dynamic>>(
      path,
      queryParameters: {
        'page': page,
        'size': size,
        'sort': path == '/users' ? 'username,asc' : 'dueAt,asc',
        if (status != null) 'status': status,
        if (search.isNotEmpty) 'search': search,
      },
    );
    final data = response.data!;
    return PageResult(
      items:
          (data['items'] as List)
              .map((v) => Map<String, dynamic>.from(v as Map))
              .toList(),
      page: (data['page'] as num).toInt(),
      size: (data['size'] as num).toInt(),
      total: (data['total'] as num).toInt(),
    );
  });
  Future<void> renew(int id) => apiGuard(() async {
    await dio.post<dynamic>('/loans/$id/renew', data: {'days': 14});
  });
  Future<void> closeLoan(int id) => apiGuard(() async {
    await dio.post<dynamic>('/loans/$id/return');
  });
  Future<void> changeRole(int id, Role role) => apiGuard(() async {
    await dio.patch<dynamic>('/users/$id/role', data: {'role': role.name});
  });
  Future<Map<String, dynamic>> statistics() => apiGuard(() async {
    final response = await dio.get<Map<String, dynamic>>('/statistics');
    return response.data!;
  });
}
