import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../state/auth_notifier.dart';
import '../widgets/states.dart';

class SessionScreen extends StatelessWidget {
  const SessionScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child:
              auth.restoring
                  ? const LoadingState()
                  : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ErrorState(
                        message:
                            auth.restoreError ??
                            'Не удалось восстановить сеанс.',
                        onRetry: auth.restore,
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: auth.logout,
                        child: const Text('Перейти ко входу'),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }
}

class ForbiddenScreen extends StatelessWidget {
  const ForbiddenScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Доступ запрещён')),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            const Text(
              'У вашей роли нет доступа к этому разделу.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/'),
              child: const Text('На главную'),
            ),
          ],
        ),
      ),
    ),
  );
}
