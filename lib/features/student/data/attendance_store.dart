import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Modèle ───────────────────────────────────────────────────────────────
class AttendanceRecord {
  final String id;
  final String studentId;
  final String studentName;
  final String className;
  final String subject;
  final String date; // dd/MM/yyyy
  final String duration; // ex: "2h"
  final bool isLate; // retard vs absence

  String status; // Absent | En attente | Justifiée
  String? justificationMotif;
  String? justificatifPath;
  String? smsId;
  bool smsSent;

  AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.subject,
    required this.date,
    required this.duration,
    this.isLate = false,
    this.status = 'Absent',
    this.justificationMotif,
    this.justificatifPath,
    this.smsId,
    this.smsSent = false,
  });

  // Libellé affiché selon le type
  String get typeLabel => isLate ? 'Retard' : 'Absence';

  Map<String, dynamic> toJson() => {
        'id': id,
        'studentId': studentId,
        'studentName': studentName,
        'className': className,
        'subject': subject,
        'date': date,
        'duration': duration,
        'isLate': isLate,
        'status': status,
        'justificationMotif': justificationMotif,
        'justificatifPath': justificatifPath,
        'smsId': smsId,
        'smsSent': smsSent,
      };

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      studentId: json['studentId'] ?? '',
      studentName: json['studentName'],
      className: json['className'] ?? '',
      subject: json['subject'],
      date: json['date'],
      duration: json['duration'],
      isLate: json['isLate'] ?? false,
      status: json['status'],
      justificationMotif: json['justificationMotif'],
      justificatifPath: json['justificatifPath'],
      smsId: json['smsId'],
      smsSent: json['smsSent'] ?? false,
    );
  }

  factory AttendanceRecord.fromApi(
    Map<String, dynamic> json, {
    String studentName = '',
    String className = '',
  }) {
    final statusRaw = (json['status']?.toString() ?? '').toUpperCase();
    final isJustified = json['isJustified'] == true;
    final isLate = json['isLate'] == true || statusRaw == 'LATE';
    String status;
    if (isJustified) {
      status = 'Justifiée';
    } else if (statusRaw == 'ABSENT' || statusRaw == 'LATE') {
      status = 'Absent';
    } else {
      status = statusRaw.isEmpty ? 'Absent' : statusRaw;
    }

    final dt = DateTime.tryParse(json['date']?.toString() ?? '');
    final dateStr = dt == null
        ? (json['date']?.toString() ?? '')
        : '${dt.day.toString().padLeft(2, '0')}/'
            '${dt.month.toString().padLeft(2, '0')}/'
            '${dt.year}';

    return AttendanceRecord(
      id: json['id']?.toString() ?? '',
      studentId: json['studentId']?.toString() ?? '',
      studentName: studentName,
      className: className,
      subject: json['subject']?.toString() ?? '',
      date: dateStr,
      duration: isLate
          ? '${json['lateMinutes'] ?? 0} min'
          : '1 séance',
      isLate: isLate,
      status: status,
      justificationMotif: json['justification'] as String?,
    );
  }
}

// ─── Store (compatibilité legacy — le provider Riverpod est la source principale) ──
class AttendanceStore {
  static const _storageKey = 'attendance_records';
  static List<AttendanceRecord> _records = [];

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);
    if (data != null) {
      final List decoded = jsonDecode(data);
      _records = decoded.map((e) => AttendanceRecord.fromJson(e)).toList();
    }
  }

  static Future<void> addRecord(AttendanceRecord record) async {
    _records.add(record);
    await _save();
  }

  static List<AttendanceRecord> getRecords() => List.unmodifiable(_records);

  static List<AttendanceRecord> getByStudent(String studentId) =>
      _records.where((r) => r.studentId == studentId).toList();

  static Future<void> justifyAbsence({
    required String recordId,
    required String motif,
    String? justificatifPath,
  }) async {
    final idx = _records.indexWhere((r) => r.id == recordId);
    if (idx != -1) {
      _records[idx].status = 'En attente';
      _records[idx].justificationMotif = motif;
      _records[idx].justificatifPath = justificatifPath;
      await _save();
    }
  }

  static Future<void> validateJustification(String recordId) async {
    final idx = _records.indexWhere((r) => r.id == recordId);
    if (idx != -1) {
      _records[idx].status = 'Justifiée';
      await _save();
    }
  }

  static Future<void> clear() async {
    _records.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  static Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_records.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }
}
