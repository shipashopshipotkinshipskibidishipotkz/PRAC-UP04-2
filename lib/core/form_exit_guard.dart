import 'package:flutter/material.dart';
class FormExitGuard {
  Object? owner;
  Future<bool> Function()? confirm;
  Future<bool> canLeave(BuildContext context) async =>
      await confirm?.call() ?? true;
  void detach(Object token) {
    if (identical(owner, token)) {
      owner = null;
      confirm = null;
    }
  }
}
