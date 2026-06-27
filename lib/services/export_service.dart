import 'dart:io';
import '../features/student/data/attendance_store.dart';

class ExportService {
  static Future<File> exportAbsencesCsv() async {
    final records = AttendanceStore.getRecords();

    final buffer = StringBuffer();
    buffer.writeln('Élève,Matière,Date,Durée,Statut,Justification');

    for (final r in records) {
      buffer.writeln(
        '${r.studentName},${r.subject},${r.date},${r.duration},${r.status},${r.justificationMotif ?? ''}',
      );
    }

    final file = File('/storage/emulated/0/Download/absences_ecole_plus.csv');
    return file.writeAsString(buffer.toString());
  }
}
