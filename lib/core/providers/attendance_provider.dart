import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/student/data/attendance_store.dart';

// ─── Notifier ─────────────────────────────────────────────────────────────
class AttendanceNotifier extends StateNotifier<List<AttendanceRecord>> {
  static const _storageKey = 'attendance_records';

  AttendanceNotifier() : super([]);

  // Chargement initial
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);
    if (data != null) {
      final List decoded = jsonDecode(data);
      state = decoded.map((e) => AttendanceRecord.fromJson(e)).toList();
    }
  }

  // Ajouter une ou plusieurs absences (après appel enseignant)
  Future<void> addRecords(List<AttendanceRecord> records) async {
    state = [...state, ...records];
    await _save();

    // Déclencher notification push pour chaque absence
    for (final record in records) {
      if (!record.isLate) {
        await NotificationService.instance.notifyAbsence(
          studentName: record.studentName,
          subject: record.subject,
          date: record.date,
          parentPhone: '',
        );
      }
    }
  }

  // Parent soumet une justification
  Future<void> justifyAbsence({
    required String recordId,
    required String motif,
    String? justificatifPath,
  }) async {
    state = [
      for (final r in state)
        if (r.id == recordId)
          AttendanceRecord(
            id: r.id,
            studentId: r.studentId,
            studentName: r.studentName,
            className: r.className,
            subject: r.subject,
            date: r.date,
            duration: r.duration,
            isLate: r.isLate,
            status: 'En attente',
            justificationMotif: motif,
            justificatifPath: justificatifPath,
            smsId: r.smsId,
            smsSent: r.smsSent,
          )
        else
          r,
    ];
    await _save();
  }

  // Admin valide une justification
  Future<void> validateJustification(String recordId) async {
    state = [
      for (final r in state)
        if (r.id == recordId)
          AttendanceRecord(
            id: r.id,
            studentId: r.studentId,
            studentName: r.studentName,
            className: r.className,
            subject: r.subject,
            date: r.date,
            duration: r.duration,
            isLate: r.isLate,
            status: 'Justifiée',
            justificationMotif: r.justificationMotif,
            justificatifPath: r.justificatifPath,
            smsId: r.smsId,
            smsSent: r.smsSent,
          )
        else
          r,
    ];
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(state.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }
}

// ─── Provider global ──────────────────────────────────────────────────────
final attendanceProvider =
    StateNotifierProvider<AttendanceNotifier, List<AttendanceRecord>>(
  (ref) => AttendanceNotifier(),
);

// ─── Providers dérivés ────────────────────────────────────────────────────

// Absences d'un élève spécifique
final absencesByStudentProvider =
    Provider.family<List<AttendanceRecord>, String>((ref, studentId) {
  return ref
      .watch(attendanceProvider)
      .where((r) => r.studentId == studentId)
      .toList();
});

// Absences en attente de validation (pour admin)
final pendingJustificationsProvider = Provider<List<AttendanceRecord>>((ref) {
  return ref
      .watch(attendanceProvider)
      .where((r) => r.status == 'En attente')
      .toList();
});

// Stats rapides pour dashboard
final attendanceStatsProvider = Provider<Map<String, int>>((ref) {
  final records = ref.watch(attendanceProvider);
  return {
    'total': records.length,
    'absent': records.where((r) => r.status == 'Absent').length,
    'enAttente': records.where((r) => r.status == 'En attente').length,
    'justifiee': records.where((r) => r.status == 'Justifiée').length,
  };
});
