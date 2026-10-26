import 'package:go_router/go_router.dart';
import '../screens/home_screen.dart';
import '../screens/book_list_screen.dart';
import '../screens/book_detail_screen.dart';
import '../screens/author_list_screen.dart';
import '../screens/author_detail_screen.dart';
import '../screens/not_found_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/books',
      builder: (context, state) => const BookListScreen(),
      routes: [
        GoRoute(
          path: ':id',
          builder: (context, state) => BookDetailScreen(
            bookId: int.parse(state.pathParameters['id']!),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/authors',
      builder: (context, state) => const AuthorListScreen(),
      routes: [
        GoRoute(
          path: ':id',
          builder: (context, state) => AuthorDetailScreen(
            authorId: int.parse(state.pathParameters['id']!),
          ),
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) => NotFoundScreen(location: state.uri.toString()),
);