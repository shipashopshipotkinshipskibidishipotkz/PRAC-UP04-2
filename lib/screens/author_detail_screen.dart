import 'package:flutter/material.dart';
import '../models/entity_kind.dart';
import 'entity_detail_screen.dart';

class AuthorDetailScreen extends StatelessWidget {
  final int authorId;
  const AuthorDetailScreen({super.key, required this.authorId});
  @override
  Widget build(BuildContext context) =>
      EntityDetailScreen(kind: EntityKind.authors, id: authorId);
}
