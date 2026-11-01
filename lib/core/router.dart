import 'package:go_router/go_router.dart';
import '../models/entity_kind.dart';
import '../screens/catalog_list_screen.dart';
import '../screens/entity_detail_screen.dart';
import '../screens/entity_form_screen.dart';
import '../screens/home_screen.dart';
import '../screens/not_found_screen.dart';
import 'form_exit_guard.dart';

GoRouter createAppRouter(FormExitGuard guard) => GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    for (final kind in EntityKind.values)
      GoRoute(
        path: kind.path,
        builder:
            (context, state) => CatalogListScreen(
              kind: kind,
              queryParameters: state.uri.queryParameters,
            ),
        routes: [
          GoRoute(
            path: 'new',
            builder:
                (context, state) =>
                    EntityFormScreen(key: state.pageKey, kind: kind),
            onExit: (context, state) => guard.canLeave(context),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '');
              return id == null || id < 1
                  ? NotFoundScreen(location: state.uri.toString())
                  : EntityDetailScreen(kind: kind, id: id);
            },
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) {
                  final id = int.tryParse(state.pathParameters['id'] ?? '');
                  return id == null || id < 1
                      ? NotFoundScreen(location: state.uri.toString())
                      : EntityFormScreen(
                        key: state.pageKey,
                        kind: kind,
                        id: id,
                      );
                },
                onExit: (context, state) => guard.canLeave(context),
              ),
            ],
          ),
        ],
      ),
  ],
  errorBuilder:
      (context, state) => NotFoundScreen(location: state.uri.toString()),
);
