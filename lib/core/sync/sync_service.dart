import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/app_database.dart';
import 'offline_outbox.dart';

enum SyncStatus { idle, syncing, success, error }

class SyncResult {
  final SyncStatus status;
  final String? message;
  final int itemsSynced;

  const SyncResult({
    required this.status,
    this.message,
    this.itemsSynced = 0,
  });
}

// ─── Service de synchronisation SharedPreferences → SQLite + outbox API ───
class SyncService {
  Future<SyncResult> syncAll() async {
    debugPrint('🔄 Sync démarrée...');
    int total = 0;
    try {
      total += await OfflineOutbox.flush();
      total += await _syncStudents();
      total += await _syncAttendance();
      total += await _syncGrades();
      total += await _syncClasses();
      total += await _syncFees();
      total += await _syncPayments();
      debugPrint('✅ Sync terminée — $total éléments');
      return SyncResult(
        status: SyncStatus.success,
        itemsSynced: total,
        message:
            '$total élément${total > 1 ? 's' : ''} synchronisé${total > 1 ? 's' : ''}',
      );
    } catch (e) {
      debugPrint('❌ Erreur sync : $e');
      return SyncResult(
        status: SyncStatus.error,
        message: 'Erreur : $e',
      );
    }
  }

  Future<int> _syncStudents() async {
    final data = await _load('students');
    if (data == null) return 0;
    await AppDatabase.upsertStudents(data.cast<Map<String, dynamic>>());
    return data.length;
  }

  Future<int> _syncAttendance() async {
    final data = await _load('attendance_records');
    if (data == null) return 0;
    await AppDatabase.upsertAttendance(data.cast<Map<String, dynamic>>());
    return data.length;
  }

  Future<int> _syncGrades() async {
    final data = await _load('grades');
    if (data == null) return 0;
    await AppDatabase.upsertGrades(data.cast<Map<String, dynamic>>());
    return data.length;
  }

  Future<int> _syncClasses() async {
    final data = await _load('school_classes');
    if (data == null) return 0;
    await AppDatabase.upsertClasses(data.cast<Map<String, dynamic>>());
    return data.length;
  }

  Future<int> _syncFees() async {
    final data = await _load('school_fees');
    if (data == null) return 0;
    await AppDatabase.upsertFees(data.cast<Map<String, dynamic>>());
    return data.length;
  }

  Future<int> _syncPayments() async {
    final data = await _load('payments');
    if (data == null) return 0;
    await AppDatabase.upsertPayments(data.cast<Map<String, dynamic>>());
    return data.length;
  }

  Future<List?> _load(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return null;
    final decoded = jsonDecode(raw) as List;
    return decoded.isEmpty ? null : decoded;
  }

  Future<List<Map<String, dynamic>>> getUnsyncedData() async {
    final payments = await AppDatabase.getUnsyncedPayments();
    final attendance = await AppDatabase.getPendingAttendance();
    return [
      ...payments.map((p) => {'type': 'payment', 'id': p['id']}),
      ...attendance.map((a) => {'type': 'attendance', 'id': a['id']}),
    ];
  }
}
