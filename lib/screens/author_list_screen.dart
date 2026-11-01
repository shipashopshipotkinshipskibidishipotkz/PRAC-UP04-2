import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/entity_kind.dart';
import 'catalog_list_screen.dart';

class AuthorListScreen extends StatelessWidget {
  const AuthorListScreen({super.key});
  @override
  Widget build(BuildContext context) => CatalogListScreen(
    kind: EntityKind.authors,
    queryParameters: GoRouterState.of(context).uri.queryParameters,
  );
}
