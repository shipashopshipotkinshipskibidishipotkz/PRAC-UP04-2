import 'package:go_router/go_router.dart';
import '../models/entity_kind.dart';
import '../screens/catalog_list_screen.dart';
import '../screens/entity_detail_screen.dart';
import '../screens/entity_form_screen.dart' deferred as forms;
import '../screens/home_screen.dart';
import '../screens/not_found_screen.dart';
import 'form_exit_guard.dart';
import 'permissions.dart';
import '../widgets/deferred_screen.dart';
import '../state/auth_notifier.dart';
import '../screens/auth_screen.dart';
import '../screens/session_screen.dart';
import '../screens/loans_screen.dart';
import '../screens/users_screen.dart' deferred as users;
import '../screens/statistics_screen.dart' deferred as statistics;
import '../screens/librarian_screen.dart';

GoRouter createAppRouter(
  FormExitGuard guard,
  AuthNotifier auth, {
  String? initialLocation,
}) => GoRouter(
  initialLocation: initialLocation,
  refreshListenable: auth,
  redirect: (context, state) {
    final path = state.uri.path;
    final public = path == '/login' || path == '/register';
    final from = safeReturnLocation(state.uri.queryParameters['from']);
    if (auth.restoring || auth.restoreError != null) {
      return path == '/session'
          ? null
          : Uri(
            path: '/session',
            queryParameters: {'from': public ? from : state.uri.toString()},
          ).toString();
    }
    if (!auth.isAuthenticated) {
      if (public) return null;
      return Uri(
        path: '/login',
        queryParameters: {
          'from': path == '/session' ? from : state.uri.toString(),
        },
      ).toString();
    }
    if (public || path == '/session') return from;
    if (path != '/forbidden' && !auth.can(permissionForPath(path))) {
      return '/forbidden';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder:
          (_, s) =>
              AuthScreen(key: s.pageKey, from: s.uri.queryParameters['from']),
    ),
    GoRoute(
      path: '/register',
      builder:
          (_, s) => AuthScreen(
            key: s.pageKey,
            register: true,
            from: s.uri.queryParameters['from'],
          ),
    ),
    GoRoute(path: '/session', builder: (_, _) => const SessionScreen()),
    GoRoute(path: '/forbidden', builder: (_, _) => const ForbiddenScreen()),
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/my-loans', builder: (_, _) => const LoansScreen(own: true)),
    GoRoute(path: '/loans', builder: (_, _) => const LoansScreen()),
    GoRoute(path: '/desk', builder: (_, _) => const LibrarianScreen()),
    GoRoute(
      path: '/admin/users',
      builder:
          (_, _) => DeferredScreen(
            load: users.loadLibrary,
            builder: () => users.UsersScreen(),
          ),
    ),
    GoRoute(
      path: '/admin/statistics',
      builder:
          (_, _) => DeferredScreen(
            load: statistics.loadLibrary,
            builder: () => statistics.StatisticsScreen(),
          ),
    ),
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
                (context, state) => DeferredScreen(
                  key: state.pageKey,
                  load: forms.loadLibrary,
                  builder: () => forms.EntityFormScreen(kind: kind),
                ),
            onExit:
                (context, state) async =>
                    !auth.isAuthenticated ||
                    !auth.can(Permission.editCatalog) ||
                    await guard.canLeave(context),
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
                      : DeferredScreen(
                        key: state.pageKey,
                        load: forms.loadLibrary,
                        builder:
                            () => forms.EntityFormScreen(kind: kind, id: id),
                      );
                },
                onExit:
                    (context, state) async =>
                        !auth.isAuthenticated ||
                        !auth.can(Permission.editCatalog) ||
                        await guard.canLeave(context),
              ),
            ],
          ),
        ],
      ),
  ],
  errorBuilder:
      (context, state) => NotFoundScreen(location: state.uri.toString()),
);
