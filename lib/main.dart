import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/form_exit_guard.dart';
import 'core/router.dart';
import 'repositories/persistent_library_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  try {
    final repository = await PersistentLibraryRepository.open();
    runApp(LibraryApp(repository: repository));
  } catch (error) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Не удалось открыть хранилище браузера. Разрешите локальное хранение данных и обновите страницу.\n$error',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LibraryApp extends StatefulWidget {
  final PersistentLibraryRepository repository;
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
