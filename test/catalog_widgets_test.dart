import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_web/models/app_user.dart';
import 'support/mock_api.dart';
import 'support/test_app.dart';

void main() {
  group('Состояния списка — ПР6', () {
    testWidgets('во время запроса отображается индикатор загрузки', (
      tester,
    ) async {
      await withTestApp(tester, (app) async {
        final response = Completer<MockResponse>();
        app.adapter.respond =
            (request) =>
                request.path == '/books'
                    ? response.future
                    : catalogResponse(request);
        app.router.go('/books');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        response.complete((200, pageJson([])));
        await tester.pumpAndSettle();
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });
    });
    testWidgets('пустой результат показывает сообщение вместо таблицы', (
      tester,
    ) async {
      await withTestApp(tester, (app) async {
        app.adapter.respond =
            (request) =>
                request.path == '/books'
                    ? (200, pageJson([]))
                    : catalogResponse(request);
        app.router.go('/books');
        await tester.pumpAndSettle();
        expect(find.textContaining('Записи не найдены'), findsOneWidget);
        expect(find.byType(DataTable), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });
    });
    testWidgets(
      'ошибка содержит кнопку повтора, которая восстанавливает список',
      (tester) async {
        await withTestApp(tester, (app) async {
          app.adapter.respond =
              (request) =>
                  request.path == '/books'
                      ? (500, {'message': 'Сервер недоступен'})
                      : catalogResponse(request);
          app.router.go('/books');
          await tester.pumpAndSettle();
          expect(find.text('Сервер недоступен'), findsOneWidget);
          expect(find.text('Повторить'), findsOneWidget);
          app.adapter.respond = catalogResponse;
          await tester.ensureVisible(find.text('Повторить'));
          await tester.tap(find.text('Повторить'));
          await tester.pumpAndSettle();
          expect(find.text('Повторить'), findsNothing);
          expect(find.byType(DataTable), findsOneWidget);
          expect(find.text('Война и мир'), findsWidgets);
        });
      },
    );
    testWidgets(
      'читателю скрыты изменение и удаление, чужой маршрут запрещён',
      (tester) async {
        await withTestApp(tester, (app) async {
          app.router.go('/books');
          await tester.pumpAndSettle();
          expect(find.text('Добавить'), findsNothing);
          expect(find.byTooltip('Редактировать'), findsNothing);
          expect(find.byTooltip('Удалить навсегда'), findsNothing);
          app.router.go('/admin/users');
          await tester.pumpAndSettle();
          expect(find.text('Доступ запрещён'), findsOneWidget);
        }, role: Role.reader);
      },
    );
  });
}
