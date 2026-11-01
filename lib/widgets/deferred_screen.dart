import 'package:flutter/material.dart';
import 'states.dart';

class DeferredScreen extends StatefulWidget {
  final Future<void> Function() load;
  final Widget Function() builder;
  const DeferredScreen({super.key, required this.load, required this.builder});
  @override
  State<DeferredScreen> createState() => _DeferredScreenState();
}

class _DeferredScreenState extends State<DeferredScreen> {
  late Future<void> _loading = widget.load();
  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _loading,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: ErrorState(
              message:
                  'Не удалось загрузить раздел. Проверьте соединение и повторите попытку.',
              onRetry: () => setState(() => _loading = widget.load()),
            ),
          ),
        );
      }
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(body: LoadingState());
      }
      return widget.builder();
    },
  );
}
