import 'package:flutter/foundation.dart';

/// Pont Dio 401 → AuthNotifier (évite import circulaire ApiClient ↔ Auth).
class AuthSessionBridge {
  static VoidCallback? onUnauthorized;

  static void notifyUnauthorized() {
    try {
      onUnauthorized?.call();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AuthSessionBridge: $e');
      }
    }
  }
}
