import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/form_exit_guard.dart';
import 'core/router.dart';
import 'core/api_client.dart';
import 'core/auth_interceptor.dart';
import 'repositories/auth_api.dart';
import 'repositories/account_repository.dart';
import 'repositories/api_library_repository.dart';
import 'repositories/library_repository.dart';
import 'state/auth_notifier.dart';
import 'widgets/session_watcher.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  final prefs = await SharedPreferences.getInstance();
  final authApi = AuthApi(buildDio());
  final auth = AuthNotifier(prefs, authApi);
  final dio = buildDio();
  attachAuthentication(dio, auth);
  runApp(
    LibraryApp(
      repository: ApiLibraryRepository(dio),
      auth: auth,
      accounts: AccountRepository(dio),
    ),
  );
  unawaited(auth.restore());
}

class LibraryApp extends StatefulWidget {
  final LibraryRepository repository;
  final AuthNotifier auth;
  final AccountRepository accounts;
  const LibraryApp({
    super.key,
    required this.repository,
    required this.auth,
    required this.accounts,
  });
  @override
  State<LibraryApp> createState() => _LibraryAppState();
}

class _LibraryAppState extends State<LibraryApp> {
  final _guard = FormExitGuard();
  late final GoRouter _router = createAppRouter(_guard, widget.auth);
  int? _accountId;
  @override
  void initState() {
    super.initState();
    widget.auth.addListener(_sessionChanged);
  }

  void _sessionChanged() {
    final id = widget.auth.user?.id;
    if (_accountId != id && widget.repository is ApiLibraryRepository) {
      (widget.repository as ApiLibraryRepository).clearSessionData();
    }
    _accountId = id;
  }

  @override
  void dispose() {
    widget.auth.removeListener(_sessionChanged);
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: widget.repository),
      ChangeNotifierProvider.value(value: widget.auth),
      Provider.value(value: widget.auth.api),
      Provider.value(value: widget.accounts),
      Provider.value(value: _guard),
    ],
    child: MaterialApp.router(
      title: 'Библиотечная система',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      routerConfig: _router,
      builder: (context, child) => SessionWatcher(child: child!),
    ),
  );
}
