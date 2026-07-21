import 'package:flutter/foundation.dart';

/// Pont global pour réagir aux 401 (token expiré) depuis l'intercepteur Dio.
class AuthSessionBridge {
  static VoidCallback? onUnauthorized;
  static bool _busy = false;

  static void notifyUnauthorized() {
    if (_busy) return;
    _busy = true;
    try {
      onUnauthorized?.call();
    } finally {
      Future.microtask(() => _busy = false);
    }
  }
}
