import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_web/main.dart';
import 'package:library_web/core/router.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LibraryApp());

    expect(find.text('Библиотечная система'), findsOneWidget);
    expect(find.text('Каталог книг'), findsOneWidget);
    expect(find.text('Авторы'), findsOneWidget);
  });
}