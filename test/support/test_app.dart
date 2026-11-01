import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:library_web/main.dart';
import 'package:library_web/models/app_user.dart';
import 'package:library_web/repositories/account_repository.dart';
import 'package:library_web/repositories/api_library_repository.dart';
import 'package:library_web/repositories/auth_api.dart';
import 'package:library_web/screens/home_screen.dart';
import 'package:library_web/state/auth_notifier.dart';
import 'mock_api.dart';

class FakeAuthApi extends AuthApi {
  FakeAuthApi() : super(mockDio(MockApiAdapter()));

  @override
  Future<AuthResult> login(String username, String password) async =>
      AuthResult.fromJson({
        'accessToken': 'test-access',
        'refreshToken': 'test-refresh',
        'user': {
          'id': 1,
          'username': username,
          'fullName': 'Тестовый пользователь',
          'email': 'reader@example.org',
          'role': Role.parse(username).name,
          'readerId': 1,
        },
      });

  @override
  Future<void> logout(String refresh) async {}
}

class TestApp {
  final GoRouter router;
  final MockApiAdapter adapter;
  final Dio dio;
  final AuthNotifier auth;
  TestApp(this.router, this.adapter, this.dio, this.auth);
}

Future<void> withTestApp(
  WidgetTester tester,
  Future<void> Function(TestApp app) body, {
  Role role = Role.admin,
  double width = 1280,
}) async {
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  final auth = AuthNotifier(preferences, FakeAuthApi(), startTimer: false);
  final adapter = MockApiAdapter();
  final dio = mockDio(adapter);
  final repository = ApiLibraryRepository(dio);
  try {
    await auth.restore();
    await auth.login(role.name, 'test-password');
    await tester.pumpWidget(
      LibraryApp(
        repository: repository,
        auth: auth,
        accounts: AccountRepository(dio),
      ),
    );
    await tester.pumpAndSettle();
    final router = GoRouter.of(tester.element(find.byType(HomeScreen)));
    await body(TestApp(router, adapter, dio, auth));
  } finally {
    await tester.pumpWidget(const SizedBox.shrink());
    repository.dispose();
    auth.dispose();
    auth.api.dio.close(force: true);
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }
}
