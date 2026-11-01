import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_exceptions.dart';
import '../models/app_user.dart';
import '../models/page_result.dart';
import '../repositories/account_repository.dart';
import '../state/auth_notifier.dart';
import '../widgets/api_connection_button.dart';
import '../widgets/pagination_controls.dart';
import '../widgets/states.dart';
import '../widgets/workspace_scaffold.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});
  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  PageResult<Map<String, dynamic>> _result = PageResult.empty();
  int _page = 1;
  int _size = 10;
  int _generation = 0;
  bool _loading = true;
  final _busy = <int>{};
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await context.read<AccountRepository>().list(
        '/users',
        page: _page,
        size: _size,
      );
      if (mounted && generation == _generation) {
        setState(() {
          _result = result;
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted && generation == _generation) {
        setState(() {
          _loading = false;
          _error =
              error is ApiException
                  ? error.message
                  : 'Не удалось загрузить пользователей.';
        });
      }
    }
  }

  Future<void> _change(AppUser user, Role role) async {
    if (_busy.contains(user.id) || role == user.role) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (c) => AlertDialog(
            title: const Text('Изменить роль?'),
            content: Text(
              '${user.fullName}: ${user.role.label} → ${role.label}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('Отмена'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text('Изменить'),
              ),
            ],
          ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy.add(user.id));
    try {
      await context.read<AccountRepository>().changeRole(user.id, role);
      if (mounted) await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is ApiException
                  ? error.message
                  : 'Не удалось изменить роль.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy.remove(user.id));
    }
  }

  @override
  Widget build(BuildContext context) => WorkspaceScaffold(
    location: '/admin/users',

    appBar: AppBar(
      title: const Text('Пользователи и роли'),
      actions: const [ApiConnectionButton()],
    ),
    child: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Новые учётные записи получают роль читателя. Изменение роли проверяет сервер.',
        ),
        const SizedBox(height: 16),
        if (_loading)
          const SizedBox(height: 240, child: LoadingState())
        else if (_error != null)
          ErrorState(message: _error!, onRetry: _load)
        else ...[
          for (final data in _result.items)
            Builder(
              builder: (context) {
                final user = AppUser.fromJson(data);
                final self = context.watch<AuthNotifier>().user?.id == user.id;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 24,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SizedBox(
                          width: 260,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.fullName,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text('${user.username} · ${user.email}'),
                              if (self) const Text('Ваша учётная запись'),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 220,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Роль',
                              border: OutlineInputBorder(),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<Role>(
                                isExpanded: true,
                                key: ValueKey('${user.id}:${user.role}'),
                                value: user.role,
                                items: [
                                  for (final role in Role.values)
                                    DropdownMenuItem(
                                      value: role,
                                      child: Text(role.label),
                                    ),
                                ],
                                onChanged:
                                    self || _busy.contains(user.id)
                                        ? null
                                        : (role) {
                                          if (role != null) {
                                            _change(user, role);
                                          }
                                        },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          PaginationControls(
            pageResult: _result,
            onPageChanged: (p) {
              _page = p;
              _load();
            },
            onSizeChanged: (s) {
              _size = s;
              _page = 1;
              _load();
            },
          ),
        ],
      ],
    ),
  );
}
