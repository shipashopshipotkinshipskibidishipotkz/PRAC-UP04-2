import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../state/auth_notifier.dart';

class SessionWatcher extends StatefulWidget {
  final Widget child;
  const SessionWatcher({super.key, required this.child});
  @override
  State<SessionWatcher> createState() => _SessionWatcherState();
}

class _SessionWatcherState extends State<SessionWatcher>
    with WidgetsBindingObserver {
  late final AuthNotifier _auth;
  Timer? _cacheTimer;
  @override
  void initState() {
    super.initState();
    _auth = context.read<AuthNotifier>();
    WidgetsBinding.instance.addObserver(this);
    HardwareKeyboard.instance.addHandler(_onKey);
    _cacheTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      unawaited(_auth.syncDisplayCache());
    });
  }

  bool _onKey(KeyEvent event) {
    _auth.recordActivity();
    return false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _auth.checkSession();
  }

  @override
  void dispose() {
    _cacheTimer?.cancel();
    HardwareKeyboard.instance.removeHandler(_onKey);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final warning = context.select<AuthNotifier, int?>((a) => a.warningSeconds);
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _auth.recordActivity(),
      onPointerMove: (_) => _auth.recordActivity(),
      onPointerHover: (_) => _auth.recordActivity(),
      onPointerSignal: (_) => _auth.recordActivity(),
      child: Column(
        children: [
          if (warning != null)
            Material(
              color: Theme.of(context).colorScheme.tertiaryContainer,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 16,
                    children: [
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          'Сеанс завершится через $warning с из-за бездействия.',
                        ),
                      ),
                      TextButton(
                        onPressed: _auth.recordActivity,
                        child: const Text('Продолжить сеанс'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}
