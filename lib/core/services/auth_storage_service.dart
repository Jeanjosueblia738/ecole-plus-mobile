import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../sync/offline_outbox.dart';

class AuthStorageService {
  static const _storage = FlutterSecureStorage();

  static const _keyToken = 'jwt_token';
  static const _keyTenantCode = 'tenant_code';
  static const _keyTenantName = 'tenant_name';
  static const _keyUserRole = 'user_role';
  static const _keyUserEmail = 'user_email';
  static const _keyUserId = 'user_id';

  /// Clés session uniquement (web : ne pas prefs.clear() pour préserver le reste).
  static const _authKeys = [
    _keyToken,
    _keyTenantCode,
    _keyTenantName,
    _keyUserRole,
    _keyUserEmail,
    _keyUserId,
    'first_name',
    'last_name',
    'class_name',
  ];

  // ── Écriture ──────────────────────────────────────────────────────────
  static Future<void> _write(String key, String value) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } else {
      await _storage.write(key: key, value: value);
    }
  }

  // ── Lecture ───────────────────────────────────────────────────────────
  static Future<String?> _read(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } else {
      return _storage.read(key: key);
    }
  }

  // ── Suppression ───────────────────────────────────────────────────────
  static Future<void> _deleteAll() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      for (final key in _authKeys) {
        await prefs.remove(key);
      }
    } else {
      await _storage.deleteAll();
    }
  }

  // ── API publique ──────────────────────────────────────────────────────
  static Future<void> saveAuthData({
    required String token,
    required String tenantCode,
    required String tenantName,
    required String role,
    required String email,
    required String userId,
  }) async {
    await Future.wait([
      _write(_keyToken, token),
      _write(_keyTenantCode, tenantCode),
      _write(_keyTenantName, tenantName),
      _write(_keyUserRole, role),
      _write(_keyUserEmail, email),
      _write(_keyUserId, userId),
    ]);
  }

  static Future<String?> getToken() => _read(_keyToken);
  static Future<String?> getTenantCode() => _read(_keyTenantCode);
  static Future<String?> getTenantName() => _read(_keyTenantName);
  static Future<String?> getUserRole() => _read(_keyUserRole);
  static Future<String?> getUserEmail() => _read(_keyUserEmail);
  static Future<String?> getUserId() => _read(_keyUserId);

  // Lecture/écriture génériques
  static Future<String?> read(String key) => _read(key);
  static Future<void> write(String key, String value) => _write(key, value);

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Logout / 401 : vide la session et la file offline (évite fuite cross-user).
  static Future<void> clearAll() async {
    await OfflineOutbox.clear();
    await _deleteAll();
  }
}
