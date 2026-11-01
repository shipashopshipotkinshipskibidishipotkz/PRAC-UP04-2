import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/api_exceptions.dart';
import '../core/permissions.dart';
import '../repositories/auth_api.dart';
import '../state/auth_notifier.dart';

String? registrationPasswordError(String value) {
  if (value.length < 8) return 'Не менее 8 символов';
  if (!RegExp(r'\d').hasMatch(value)) return 'Добавьте хотя бы одну цифру';
  if (!RegExp(r'[^\p{L}\p{N}\s]', unicode: true).hasMatch(value)) {
    return 'Добавьте специальный символ';
  }
  return null;
}

class AuthScreen extends StatefulWidget {
  final bool register;
  final String? from;
  const AuthScreen({super.key, this.register = false, this.from});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  Map<String, String> _errors = {};
  bool _busy = false;
  bool _obscure = true;
  String? _error;
  @override
  void dispose() {
    for (final c in [_username, _password, _confirmation, _fullName, _email]) {
      c.dispose();
    }
    super.dispose();
  }

  void _changed(String _) {
    setState(() {
      _errors = {};
      _error = null;
    });
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Обязательное поле' : null;
  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
      _errors = {};
    });
    try {
      if (widget.register) {
        await context.read<AuthApi>().register({
          'username': _username.text.trim(),
          'password': _password.text,
          'fullName': _fullName.text.trim(),
          'email': _email.text.trim(),
        });
        if (!mounted) return;
      }
      await context.read<AuthNotifier>().login(_username.text, _password.text);
      if (mounted) context.go(safeReturnLocation(widget.from));
    } on ValidationException catch (error) {
      if (mounted) {
        setState(() => _errors = error.errors);
        _form.currentState!.validate();
      }
    } catch (error) {
      if (mounted) {
        setState(
          () =>
              _error =
                  error is ApiException
                      ? error.message
                      : 'Не удалось выполнить вход. Попробуйте ещё раз.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _field(
    TextEditingController controller,
    String name,
    String label, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Iterable<String>? hints,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controller,
      enabled: !_busy,
      keyboardType: keyboardType,
      autofillHints: hints,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      onChanged: _changed,
      validator: (v) => _errors[name] ?? (validator ?? _required)(v),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final registering = widget.register;
    return Scaffold(
      appBar: AppBar(title: const Text('Библиотечная система')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: AutofillGroup(
              child: Form(
                key: _form,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      registering
                          ? Icons.person_add_outlined
                          : Icons.menu_book_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      registering
                          ? 'Регистрация читателя'
                          : 'Вход в библиотеку',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 24),
                    if (auth.message != null && !registering) ...[
                      Semantics(
                        liveRegion: true,
                        child: Text(auth.message!, textAlign: TextAlign.center),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (registering)
                      _field(
                        _fullName,
                        'fullName',
                        'ФИО',
                        hints: [AutofillHints.name],
                      ),
                    _field(
                      _username,
                      'username',
                      'Логин',
                      hints: [
                        registering
                            ? AutofillHints.newUsername
                            : AutofillHints.username,
                      ],
                      validator:
                          (v) =>
                              _required(v) ??
                              (registering && v!.trim().length < 3
                                  ? 'Не менее 3 символов'
                                  : null),
                    ),
                    if (registering)
                      _field(
                        _email,
                        'email',
                        'Электронная почта',
                        keyboardType: TextInputType.emailAddress,
                        hints: [AutofillHints.email],
                        validator:
                            (v) =>
                                _required(v) ??
                                (!RegExp(
                                      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                    ).hasMatch(v!.trim())
                                    ? 'Введите корректную почту'
                                    : null),
                      ),
                    TextFormField(
                      controller: _password,
                      enabled: !_busy,
                      obscureText: _obscure,
                      autofillHints: [
                        registering
                            ? AutofillHints.newPassword
                            : AutofillHints.password,
                      ],
                      decoration: InputDecoration(
                        labelText: 'Пароль',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip:
                              _obscure ? 'Показать пароль' : 'Скрыть пароль',
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      onChanged: _changed,
                      validator:
                          (v) =>
                              _errors['password'] ??
                              _required(v) ??
                              (registering
                                  ? registrationPasswordError(v!)
                                  : null),
                      onFieldSubmitted: (_) {
                        if (!registering) _submit();
                      },
                    ),
                    if (registering) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Не менее 8 символов, цифра и специальный символ',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmation,
                        enabled: !_busy,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Повторите пароль',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: _changed,
                        validator:
                            (v) =>
                                v == _password.text && v!.isNotEmpty
                                    ? null
                                    : 'Пароли должны совпадать',
                        onFieldSubmitted: (_) => _submit(),
                      ),
                    ],
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child:
                            _busy
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : Text(
                                  registering ? 'Зарегистрироваться' : 'Войти',
                                ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed:
                          _busy
                              ? null
                              : () => context.go(
                                Uri(
                                  path: registering ? '/login' : '/register',
                                  queryParameters:
                                      widget.from == null
                                          ? null
                                          : {'from': widget.from!},
                                ).toString(),
                              ),
                      child: Text(
                        registering
                            ? 'Уже есть учётная запись? Войти'
                            : 'Создать учётную запись',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
