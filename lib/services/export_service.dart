import 'dart:io';
import '../core/services/attendance_api_service.dart';

class ExportService {
  /// Export CSV des absences depuis l'API (classe + date).
  /// Ne s'appuie plus sur AttendanceStore (prefs locales non fiables).
  static Future<File> exportAbsencesCsv({
    required String classId,
    required String date,
  }) async {
    if (classId.isEmpty || date.isEmpty) {
      throw StateError(
        'Export impossible : classe et date serveur requises.',
      );
    }

    final rows = await AttendanceApiService.getByClass(classId, date);
    if (rows.isEmpty) {
      throw StateError('Aucune absence à exporter pour cette date.');
    }

    final buffer = StringBuffer();
    buffer.writeln('Élève,Matière,Date,Statut,Justification');

    for (final raw in rows) {
      if (raw is! Map) continue;
      final r = Map<String, dynamic>.from(raw);
      final student = r['student'] is Map
          ? Map<String, dynamic>.from(r['student'] as Map)
          : <String, dynamic>{};
      final name = [
        student['firstName']?.toString() ?? '',
        student['lastName']?.toString() ?? '',
      ].where((p) => p.isNotEmpty).join(' ');
      final subject = r['subject']?.toString() ?? '';
      final status = r['status']?.toString() ?? '';
      final justification = r['justification']?.toString() ?? '';
      buffer.writeln(
        '${_csv(name)},${_csv(subject)},${_csv(date)},${_csv(status)},${_csv(justification)}',
      );
    }

    final file = File('/storage/emulated/0/Download/absences_ecole_plus.csv');
    return file.writeAsString(buffer.toString());
  }

  static String _csv(String value) {
    final escaped = value.replaceAll('"', '""');
    if (escaped.contains(',') || escaped.contains('"') || escaped.contains('\n')) {
      return '"$escaped"';
    }
    return escaped;
  }
}
