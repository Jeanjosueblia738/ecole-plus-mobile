import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/student/data/attendance_store.dart';
import '../services/attendance_api_service.dart';
import '../../services/notification_service.dart';

// ─── Notifier (source = API) ───────────────────────────────────────────────
class AttendanceNotifier extends StateNotifier<List<AttendanceRecord>> {
  AttendanceNotifier() : super([]);

  bool loading = false;
  String? error;

  Future<void> loadForStudent(
    String studentId, {
    String studentName = '',
    String className = '',
  }) async {
    loading = true;
    error = null;
    try {
      final data = await AttendanceApiService.getByStudent(studentId);
      final raw = (data['attendances'] as List?) ?? [];
      final incoming = raw
          .where((e) {
            final s = (e is Map ? e['status']?.toString() : null)?.toUpperCase();
            return s == 'ABSENT' || s == 'LATE' || e is Map && e['isLate'] == true;
          })
          .map((e) => AttendanceRecord.fromApi(
                Map<String, dynamic>.from(e as Map),
                studentName: studentName,
                className: className,
              ))
          .toList();

      state = [
        ...state.where((r) => r.studentId != studentId),
        ...incoming,
      ];
    } catch (e) {
      error = 'Impossible de charger les absences';
    } finally {
      loading = false;
    }
  }

  Future<void> addRecords(List<AttendanceRecord> records) async {
    state = [...state, ...records];
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

  Future<void> justifyAbsence({
    required String recordId,
    required String motif,
    String? justificatifPath,
  }) async {
    await AttendanceApiService.justify(recordId, motif);
    // Soumission parent → en attente de validation admin (pas encore Justifiée).
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
  }

  /// Validation admin. Pas d'endpoint API dédié pour l'instant — sync locale.
  // TODO: brancher sur PATCH/PUT /attendance/:id/validate quand l'API existera.
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
  }
}

final attendanceProvider =
    StateNotifierProvider<AttendanceNotifier, List<AttendanceRecord>>(
  (ref) => AttendanceNotifier(),
);

final absencesByStudentProvider =
    Provider.family<List<AttendanceRecord>, String>((ref, studentId) {
  return ref
      .watch(attendanceProvider)
      .where((r) => r.studentId == studentId)
      .toList();
});

final pendingJustificationsProvider = Provider<List<AttendanceRecord>>((ref) {
  return ref
      .watch(attendanceProvider)
      .where((r) => r.status == 'En attente')
      .toList();
});

final attendanceStatsProvider = Provider<Map<String, int>>((ref) {
  final records = ref.watch(attendanceProvider);
  return {
    'total': records.length,
    'absent': records.where((r) => r.status == 'Absent').length,
    'enAttente': records.where((r) => r.status == 'En attente').length,
    'justifiee': records.where((r) => r.status == 'Justifiée').length,
  };
});
