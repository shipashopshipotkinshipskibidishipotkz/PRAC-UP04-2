import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/entity_kind.dart';
import 'catalog_list_screen.dart';

class BookListScreen extends StatelessWidget {
  const BookListScreen({super.key});
  @override
  Widget build(BuildContext context) => CatalogListScreen(
    kind: EntityKind.books,
    queryParameters: GoRouterState.of(context).uri.queryParameters,
  );
}
