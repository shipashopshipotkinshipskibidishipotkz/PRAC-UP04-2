import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/test_app.dart';

void main() {
  for (final width in [360.0, 768.0, 1280.0, 1920.0]) {
    testWidgets('основные экраны помещаются при ширине $width — ПР6', (
      tester,
    ) async {
      await withTestApp(tester, (app) async {
        for (final path in [
          '/',
          '/books',
          '/authors',
          '/genres',
          '/publishers',
          '/readers',
          '/books/1',
          '/authors/1',
          '/genres/1',
          '/publishers/1',
          '/readers/1',
          '/books/new',
          '/authors/new',
          '/genres/new',
          '/publishers/new',
          '/readers/new',
          '/books/1/edit',
          '/loans',
          '/admin/users',
          '/admin/statistics',
        ]) {
          app.router.go(path);
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '$path at width $width',
          );
          expect(
            find.text('Повторить'),
            findsNothing,
            reason: '$path did not load',
          );
          if (path == '/books') {
            expect(
              find.byType(NavigationBar),
              width < 600 ? findsOneWidget : findsNothing,
            );
            expect(
              find.byType(NavigationRail),
              width >= 600 ? findsOneWidget : findsNothing,
            );
            expect(
              find.byType(DataTable),
              width >= 1200 ? findsOneWidget : findsNothing,
            );
          }
        }
      }, width: width);
    });
  }
  testWidgets('изменение ширины сохраняет поиск и страницу списка', (
    tester,
  ) async {
    await withTestApp(tester, (app) async {
      app.router.go('/books?search=война&page=2');
      await tester.pumpAndSettle();
      for (final width in [360.0, 768.0, 1280.0, 1920.0]) {
        tester.view.physicalSize = Size(width, 1000);
        await tester.pumpAndSettle();
        expect(
          app.router.routeInformationProvider.value.uri.queryParameters,
          containsPair('search', 'война'),
        );
        expect(
          app.router.routeInformationProvider.value.uri.queryParameters,
          containsPair('page', '2'),
        );
        expect(tester.takeException(), isNull);
      }
    });
  });
}
