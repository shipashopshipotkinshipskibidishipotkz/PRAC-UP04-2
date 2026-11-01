import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_exceptions.dart';
import '../core/permissions.dart';
import '../models/app_user.dart';
import '../repositories/auth_api.dart';

class AuthNotifier extends ChangeNotifier {
  static const accessKey = 'auth_access_token';
  static const refreshKey = 'auth_refresh_token';
  static const userKey = 'auth_user';
  static const startedKey = 'auth_started_at';
  static const activityKey = 'auth_last_activity';
  final SharedPreferences prefs;
  final AuthApi api;
  final DateTime Function() now;
  final Duration inactivity;
  final Duration maximum;
  Timer? _timer;
  Future<void>? _refreshing;
  Future<void> _storageWrites = Future.value();
  int _generation = 0;
  bool _disposed = false;
  bool restoring = true;
  String? restoreError;
  String? message;
  AppUser? user;
  String? accessToken;
  String? _refreshToken;
  DateTime? _started;
  DateTime? _lastActivity;
  int? warningSeconds;

  AuthNotifier(
    this.prefs,
    this.api, {
    DateTime Function()? clock,
    this.inactivity = const Duration(
      seconds: int.fromEnvironment('INACTIVITY_SECONDS', defaultValue: 180),
    ),
    this.maximum = const Duration(
      minutes: int.fromEnvironment('SESSION_MAX_MINUTES', defaultValue: 30),
    ),
    bool startTimer = true,
  }) : now = clock ?? DateTime.now {
    if (startTimer) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        checkSession();
      });
    }
  }
  bool get isAuthenticated => user != null && accessToken != null;
  int get sessionEpoch => _generation;
  bool can(Permission permission) => allows(user?.role, permission);
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _store() {
    final values = <String, Object?>{
      accessKey: accessToken,
      refreshKey: _refreshToken,
      userKey: user == null ? null : jsonEncode(user!.toJson()),
      startedKey: _started?.millisecondsSinceEpoch,
      activityKey: _lastActivity?.millisecondsSinceEpoch,
    };
    // Serialize storage writes so a late refresh cannot restore a logged-out session.
    final next = _storageWrites.catchError((Object _) {}).then((_) async {
      for (final entry in values.entries) {
        if (entry.value == null) {
          await prefs.remove(entry.key);
        } else if (entry.value is int) {
          await prefs.setInt(entry.key, entry.value as int);
        } else {
          await prefs.setString(entry.key, entry.value as String);
        }
      }
    });
    _storageWrites = next;
    return next;
  }

  Future<void> restore() async {
    restoring = true;
    restoreError = null;
    _notify();
    final generation = ++_generation;
    await prefs.reload();
    accessToken = prefs.getString(accessKey);
    _refreshToken = prefs.getString(refreshKey);
    _started = DateTime.fromMillisecondsSinceEpoch(
      prefs.getInt(startedKey) ?? now().millisecondsSinceEpoch,
    );
    _lastActivity = DateTime.fromMillisecondsSinceEpoch(
      prefs.getInt(activityKey) ?? now().millisecondsSinceEpoch,
    );
    try {
      if (accessToken == null && _refreshToken == null) return;
      if (_expiredReason() case final String reason) {
        await logout(reason: reason);
        return;
      }
      if (accessToken != null) {
        try {
          final restoredUser = await api.me(accessToken!);
          if (generation != _generation) return;
          user = restoredUser;
        } on UnauthorizedException {
          if (generation != _generation) return;
          await refreshTokens();
        }
      } else {
        await refreshTokens();
      }
      if (generation != _generation) return;
      await _store();
    } on UnauthorizedException {
      if (generation == _generation) {
        await logout(reason: 'Сессия истекла. Войдите снова.');
      }
    } catch (error) {
      if (generation == _generation) {
        user = null;
        restoreError =
            error is ApiException
                ? error.message
                : 'Не удалось восстановить сеанс.';
      }
    } finally {
      restoring = false;
      _notify();
    }
  }

  Future<void> login(String username, String password) async {
    final generation = ++_generation;
    _refreshing = null;
    final result = await api.login(username, password);
    if (generation != _generation || _disposed) return;
    accessToken = result.accessToken;
    _refreshToken = result.refreshToken;
    user = result.user;
    _started = now();
    _lastActivity = now();
    message = null;
    restoreError = null;
    warningSeconds = null;
    await _store();
    _notify();
  }

  Future<void> refreshTokens() {
    if (_refreshing != null) return _refreshing!;
    final future = _refresh();
    _refreshing = future;
    return future.whenComplete(() {
      if (identical(_refreshing, future)) _refreshing = null;
    });
  }

  Future<void> _refresh() async {
    final generation = _generation;
    final refresh = _refreshToken;
    if (refresh == null) {
      await logout(reason: 'Сессия истекла. Войдите снова.');
      throw const UnauthorizedException();
    }
    try {
      final result = await api.refresh(refresh);
      if (generation != _generation || _disposed) {
        throw const UnauthorizedException();
      }
      if (_expiredReason() case final String reason) {
        await logout(reason: reason);
        throw const UnauthorizedException();
      }
      accessToken = result.accessToken;
      _refreshToken = result.refreshToken;
      user = result.user;
      await _store();
      _notify();
    } catch (_) {
      if (generation == _generation) {
        await logout(reason: 'Не удалось обновить сессию. Войдите снова.');
      }
      rethrow;
    }
  }

  Future<void> logout({String? reason}) async {
    final refresh = _refreshToken;
    ++_generation;
    _refreshing = null;
    user = null;
    accessToken = null;
    _refreshToken = null;
    _started = null;
    _lastActivity = null;
    warningSeconds = null;
    restoreError = null;
    restoring = false;
    message = reason;
    _notify();
    await _store();
    if (refresh != null) {
      // Local logout takes effect immediately, even when the API is unavailable.
      unawaited(api.logout(refresh).catchError((Object _) {}));
    }
  }

  String? _expiredReason() {
    if (_started != null && now().difference(_started!) >= maximum) {
      return 'Достигнута максимальная длительность сеанса. Войдите снова.';
    }
    if (_lastActivity != null &&
        now().difference(_lastActivity!) >= inactivity) {
      return 'Сеанс завершён после трёх минут бездействия. Войдите снова.';
    }
    return null;
  }

  void recordActivity() {
    if (!isAuthenticated) return;
    if (_expiredReason() case final String reason) {
      unawaited(logout(reason: reason));
      return;
    }
    final current = now();
    if (_lastActivity == null ||
        current.difference(_lastActivity!).inMilliseconds >= 500 ||
        warningSeconds != null) {
      _lastActivity = current;
      unawaited(prefs.setInt(activityKey, current.millisecondsSinceEpoch));
    }
    if (warningSeconds != null) {
      warningSeconds = null;
      _notify();
    }
  }

  void checkSession() {
    if (!isAuthenticated || restoring) return;
    if (_expiredReason() case final String reason) {
      unawaited(logout(reason: reason));
      return;
    }
    final left = inactivity - now().difference(_lastActivity!);
    final warning = left.inSeconds <= 30 ? left.inSeconds.clamp(1, 30) : null;
    if (warning != warningSeconds) {
      warningSeconds = warning;
      _notify();
    }
  }

  /// The local cache can change appearance, never server authorization.
  /// Reloading this value allows the DevTools experiment required in PR5.
  Future<void> syncDisplayCache() async {
    if (!isAuthenticated) return;
    await prefs.reload();
    final raw = prefs.getString(userKey);
    if (raw == null) return;
    try {
      final cached = AppUser.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
      if (cached.id == user?.id &&
          cached.username == user?.username &&
          (cached.role != user?.role || cached.fullName != user?.fullName)) {
        user = cached;
        _notify();
      }
    } catch (_) {
      /* A malformed UI cache does not grant permissions. */
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
