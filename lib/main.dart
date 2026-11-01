import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/form_exit_guard.dart';
import 'core/router.dart';
import 'core/api_client.dart';
import 'repositories/api_library_repository.dart';
import 'repositories/library_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  runApp(LibraryApp(repository: ApiLibraryRepository(buildDio())));
}

class LibraryApp extends StatefulWidget {
  final LibraryRepository repository;
  const LibraryApp({super.key, required this.repository});
  @override
  State<LibraryApp> createState() => _LibraryAppState();
}

class _LibraryAppState extends State<LibraryApp> {
  final _guard = FormExitGuard();
  late final GoRouter _router = createAppRouter(_guard);
  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: widget.repository),
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
    ),
  );
}
