import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/app_database.dart';
import 'offline_outbox.dart';

enum SyncStatus { idle, syncing, success, localOnly, error }

class SyncResult {
  final SyncStatus status;
  final String? message;
  /// Ops outbox poussées vers le serveur.
  final int serverSynced;
  /// Entrées prefs → SQLite (cache local, pas serveur).
  final int localCached;

  const SyncResult({
    required this.status,
    this.message,
    this.serverSynced = 0,
    this.localCached = 0,
  });

  /// Compat bandeaux : total traité (serveur prioritaire, sinon local).
  int get itemsSynced =>
      serverSynced > 0 ? serverSynced : localCached;
}

// ─── Service de synchronisation SharedPreferences → SQLite + outbox API ───
class SyncService {
  Future<SyncResult> syncAll() async {
    debugPrint('🔄 Sync démarrée...');
    try {
      final serverSynced = await OfflineOutbox.flush();
      var localCached = 0;
      localCached += await _syncStudents();
      localCached += await _syncAttendance();
      localCached += await _syncGrades();
      localCached += await _syncClasses();
      localCached += await _syncFees();
      localCached += await _syncPayments();
      debugPrint(
          '✅ Sync terminée — serveur=$serverSynced, cache local=$localCached');

      if (serverSynced > 0) {
        final localNote = localCached > 0
            ? ' (+ $localCached en cache local)'
            : '';
        return SyncResult(
          status: SyncStatus.success,
          serverSynced: serverSynced,
          localCached: localCached,
          message:
              '$serverSynced opération${serverSynced > 1 ? 's' : ''} synchronisée${serverSynced > 1 ? 's' : ''} avec le serveur$localNote',
        );
      }

      if (localCached > 0) {
        return SyncResult(
          status: SyncStatus.localOnly,
          serverSynced: 0,
          localCached: localCached,
          message:
              '$localCached élément${localCached > 1 ? 's' : ''} enregistré${localCached > 1 ? 's' : ''} en cache local (pas de sync serveur)',
        );
      }

      return const SyncResult(
        status: SyncStatus.success,
        message: 'Rien à synchroniser',
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
