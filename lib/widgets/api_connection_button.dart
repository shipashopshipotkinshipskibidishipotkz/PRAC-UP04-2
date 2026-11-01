import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_exceptions.dart';
import '../core/validators.dart';
import '../repositories/library_repository.dart';

class ApiConnectionButton extends StatelessWidget {
  const ApiConnectionButton({super.key});
  @override
  Widget build(BuildContext context) {
    final repository = context.watch<LibraryRepository>();
    return TextButton.icon(
      icon: Icon(
        repository.isAuthenticated
            ? Icons.account_circle_outlined
            : Icons.login,
      ),
      label: Text(
        repository.isAuthenticated
            ? 'Выйти: ${repository.accountName}'
            : 'Войти в учебный API',
      ),
      onPressed:
          repository.isAuthenticated
              ? repository.signOut
              : () => showDialog<void>(
                context: context,
                builder: (_) => _SignInDialog(repository: repository),
              ),
    );
  }
}

class _SignInDialog extends StatefulWidget {
  final LibraryRepository repository;
  const _SignInDialog({required this.repository});
  @override
  State<_SignInDialog> createState() => _SignInDialogState();
}

class _SignInDialogState extends State<_SignInDialog> {
  final _key = GlobalKey<FormState>();
  final _username = TextEditingController(text: 'admin');
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_key.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repository.signIn(_username.text, _password.text);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        setState(
          () =>
              _error =
                  error is ApiException ? error.message : 'Не удалось войти.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      title: const Text('Вход в учебный API'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Для просмотра вход не нужен. Изменение данных требует учётной записи учебного сервера.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _username,
                enabled: !_busy,
                decoration: const InputDecoration(
                  labelText: 'Логин',
                  border: OutlineInputBorder(),
                ),
                validator: V.text(min: 1, max: 100),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _password,
                enabled: !_busy,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Пароль',
                  border: OutlineInputBorder(),
                ),
                validator: V.required(),
                onFieldSubmitted: (_) => _submit(),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: Text(_busy ? 'Вход…' : 'Войти'),
        ),
      ],
    ),
  );
}
