import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/form_exit_guard.dart';
import '../state/auth_notifier.dart';

class ApiConnectionButton extends StatelessWidget {
  const ApiConnectionButton({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Главная',
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.home_outlined),
        ),
        if (auth.user != null)
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width < 700 ? 90 : 180,
            ),
            child: Text(
              '${auth.user!.fullName}\n${auth.user!.role.label}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        IconButton(
          tooltip: 'Выйти',
          icon: const Icon(Icons.logout),
          onPressed: () async {
            if (await context.read<FormExitGuard>().canLeave(context)) {
              await auth.logout();
            }
          },
        ),
      ],
    );
  }
}
