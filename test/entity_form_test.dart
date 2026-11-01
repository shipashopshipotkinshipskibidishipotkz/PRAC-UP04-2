import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/test_app.dart';

void main() {
  testWidgets('пустая форма показывает ошибки и не отправляет запись — ПР6', (
    tester,
  ) async {
    await withTestApp(tester, (app) async {
      app.router.go('/genres/new');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Создать запись'));
      await tester.tap(find.text('Создать запись'));
      await tester.pumpAndSettle();
      expect(find.text('Поле обязательно'), findsWidgets);
      expect(
        app.adapter.requests.where((request) => request.method != 'GET'),
        isEmpty,
      );
      expect(find.byType(TextFormField), findsWidgets);
    });
  });
}
