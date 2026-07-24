import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_client.dart';

/// File d'attente offline → POST /sync/outbox (idempotent via clientOpId).
class OfflineOutbox {
  static const _key = 'offline_outbox_v1';

  static String _newClientOpId() {
    final r = Random.secure().nextInt(0x7fffffff);
    return 'op_${DateTime.now().toUtc().microsecondsSinceEpoch}_$r';
  }

  static Future<List<Map<String, dynamic>>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  static Future<void> _save(List<Map<String, dynamic>> ops) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(ops));
  }

  /// Vide la file (logout / 401).
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    debugPrint('OfflineOutbox: cleared');
  }

  static Future<void> enqueue({
    required String type,
    required Map<String, dynamic> payload,
    String? clientOpId,
  }) async {
    final ops = await _load();
    ops.add({
      'clientOpId': clientOpId ?? _newClientOpId(),
      'type': type,
      'payload': payload,
      'createdAt': DateTime.now().toIso8601String(),
    });
    await _save(ops);
    debugPrint('OfflineOutbox: +1 ($type) — queue=${ops.length}');
  }

  static Future<int> pendingCount() async => (await _load()).length;

  /// Pousse la file vers l'API. Retourne le nombre d'ops réussies.
  static Future<int> flush() async {
    final ops = await _load();
    if (ops.isEmpty) return 0;

    final body = {
      'ops': ops
          .map((o) => {
                'clientOpId': o['clientOpId'],
                'type': o['type'],
                'payload': o['payload'],
              })
          .toList(),
    };

    try {
      final res = await ApiClient.instance.post('/sync/outbox', data: body);
      final data = res.data is Map
          ? Map<String, dynamic>.from(res.data as Map)
          : null;
      final results = (data?['results'] is List) ? data!['results'] as List : [];
      final okIds = <String>{};
      for (final r in results) {
        if (r is! Map) continue;
        final m = Map<String, dynamic>.from(r);
        if (m['ok'] == true) {
          okIds.add(m['clientOpId']?.toString() ?? '');
        }
      }
      final remaining =
          ops.where((o) => !okIds.contains(o['clientOpId']?.toString())).toList();
      await _save(remaining);
      final synced = ops.length - remaining.length;
      debugPrint('OfflineOutbox: flushed $synced, left ${remaining.length}');
      return synced;
    } catch (e) {
      debugPrint('OfflineOutbox flush failed: $e');
      return 0;
    }
  }
}
