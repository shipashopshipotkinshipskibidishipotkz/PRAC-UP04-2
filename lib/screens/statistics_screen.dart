import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_exceptions.dart';
import '../repositories/account_repository.dart';
import '../widgets/api_connection_button.dart';
import '../widgets/states.dart';
import '../widgets/workspace_scaffold.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});
  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  Map<String, dynamic>? _data;
  String? _error;
  bool _loading = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await context.read<AccountRepository>().statistics();
      if (mounted) {
        setState(() {
          _data = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error =
              e is ApiException
                  ? e.message
                  : 'Не удалось загрузить статистику.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => WorkspaceScaffold(
    location: '/admin/statistics',
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Статистика библиотеки'),
        actions: const [ApiConnectionButton()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child:
            _loading
                ? const SizedBox(height: 240, child: LoadingState())
                : _error != null
                ? ErrorState(message: _error!, onRetry: _load)
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Обновить'),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        for (final entry
                            in const {
                              'books': 'Названий книг',
                              'copies': 'Экземпляров',
                              'available': 'Свободных экземпляров',
                              'readers': 'Читателей',
                              'activeLoans': 'Активных выдач',
                              'overdueLoans': 'Просроченных выдач',
                              'users': 'Пользователей',
                            }.entries)
                          SizedBox(
                            width: 240,
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${_data![entry.key]}',
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.headlineLarge,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(entry.value),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
      ),
    ),
  );
}
