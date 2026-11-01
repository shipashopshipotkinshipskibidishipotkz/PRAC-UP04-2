import 'package:flutter/material.dart';
import '../models/entity_kind.dart';
import 'entity_detail_screen.dart';

class BookDetailScreen extends StatelessWidget {
  final int bookId;
  const BookDetailScreen({super.key, required this.bookId});
  @override
  Widget build(BuildContext context) =>
      EntityDetailScreen(kind: EntityKind.books, id: bookId);
}
