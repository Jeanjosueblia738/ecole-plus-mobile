import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Base de données SQLite — ECOLE+
// Pas de génération de code nécessaire (sqflite pur)
// ═══════════════════════════════════════════════════════════════════════════
class AppDatabase {
  static Database? _db;
  static const int _version = 1;

  // Singleton
  static Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'ecole_plus.db');

    return openDatabase(
      path,
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE students (
        id           TEXT PRIMARY KEY,
        full_name    TEXT NOT NULL,
        class_name   TEXT NOT NULL,
        parent_phone TEXT NOT NULL,
        is_synced    INTEGER NOT NULL DEFAULT 1,
        created_at   TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    await db.execute('''
      CREATE TABLE attendance (
        id                  TEXT PRIMARY KEY,
        student_id          TEXT NOT NULL,
        student_name        TEXT NOT NULL,
        class_name          TEXT NOT NULL,
        subject             TEXT NOT NULL,
        date                TEXT NOT NULL,
        duration            TEXT NOT NULL,
        is_late             INTEGER NOT NULL DEFAULT 0,
        status              TEXT NOT NULL DEFAULT 'Absent',
        justification_motif TEXT,
        justificatif_path   TEXT,
        sms_id              TEXT,
        sms_sent            INTEGER NOT NULL DEFAULT 0,
        is_synced           INTEGER NOT NULL DEFAULT 1,
        created_at          TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    await db.execute('''
      CREATE TABLE grades (
        id           TEXT PRIMARY KEY,
        student_id   TEXT NOT NULL,
        student_name TEXT NOT NULL,
        class_name   TEXT NOT NULL,
        subject      TEXT NOT NULL,
        coefficient  INTEGER NOT NULL,
        value        REAL NOT NULL,
        eval_type    TEXT NOT NULL,
        trimestre    TEXT NOT NULL,
        date         TEXT NOT NULL,
        comment      TEXT,
        is_synced    INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE classes (
        id        TEXT PRIMARY KEY,
        name      TEXT NOT NULL,
        level     TEXT NOT NULL,
        cycle     TEXT NOT NULL,
        capacity  INTEGER NOT NULL DEFAULT 45,
        is_synced INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE fees (
        id            TEXT PRIMARY KEY,
        type          TEXT NOT NULL,
        label         TEXT NOT NULL,
        montant       REAL NOT NULL,
        trimestre     TEXT NOT NULL,
        class_level   TEXT,
        obligatoire   INTEGER NOT NULL DEFAULT 1,
        date_echeance TEXT NOT NULL,
        is_synced     INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE payments (
        id             TEXT PRIMARY KEY,
        student_id     TEXT NOT NULL,
        student_name   TEXT NOT NULL,
        class_name     TEXT NOT NULL,
        fee_id         TEXT NOT NULL,
        fee_label      TEXT NOT NULL,
        montant        REAL NOT NULL,
        method         TEXT NOT NULL,
        status         TEXT NOT NULL,
        date           TEXT NOT NULL,
        operator_name  TEXT,
        phone_number   TEXT,
        transaction_id TEXT,
        cheque_number  TEXT,
        receipt_number TEXT NOT NULL,
        is_synced      INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  static Future<void> _onUpgrade(
      Database db, int oldVersion, int newVersion) async {
    // Futures migrations
  }

  // ── Utilitaire ────────────────────────────────────────────────────────
  static int boolToInt(bool v) => v ? 1 : 0;
  static bool intToBool(int? v) => (v ?? 0) == 1;

  // ═══════════════════════════════════════════════════════════════════════
  // ÉLÈVES
  // ═══════════════════════════════════════════════════════════════════════
  static Future<void> upsertStudents(
      List<Map<String, dynamic>> students) async {
    final db = await database;
    final batch = db.batch();
    for (final s in students) {
      batch.insert(
          'students',
          {
            'id': s['id'],
            'full_name': s['fullName'],
            'class_name': s['className'],
            'parent_phone': s['parentPhone'],
            'is_synced': 1,
          },
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  static Future<List<Map<String, dynamic>>> getAllStudents() async {
    final db = await database;
    final rows = await db.query('students');
    return rows
        .map((r) => {
              'id': r['id'],
              'fullName': r['full_name'],
              'className': r['class_name'],
              'parentPhone': r['parent_phone'],
            })
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PRÉSENCES
  // ═══════════════════════════════════════════════════════════════════════
  static Future<void> upsertAttendance(
      List<Map<String, dynamic>> records) async {
    final db = await database;
    final batch = db.batch();
    for (final r in records) {
      batch.insert(
          'attendance',
          {
            'id': r['id'],
            'student_id': r['studentId'],
            'student_name': r['studentName'],
            'class_name': r['className'],
            'subject': r['subject'],
            'date': r['date'],
            'duration': r['duration'],
            'is_late': boolToInt(r['isLate'] ?? false),
            'status': r['status'] ?? 'Absent',
            'justification_motif': r['justificationMotif'],
            'is_synced': 1,
          },
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  static Future<List<Map<String, dynamic>>> getAllAttendance() async {
    final db = await database;
    final rows = await db.query('attendance', orderBy: 'created_at DESC');
    return rows
        .map((r) => {
              'id': r['id'],
              'studentId': r['student_id'],
              'studentName': r['student_name'],
              'className': r['class_name'],
              'subject': r['subject'],
              'date': r['date'],
              'duration': r['duration'],
              'isLate': intToBool(r['is_late'] as int?),
              'status': r['status'],
              'justificationMotif': r['justification_motif'],
              'smsSent': intToBool(r['sms_sent'] as int?),
              'isSynced': intToBool(r['is_synced'] as int?),
            })
        .toList();
  }

  static Future<int> updateAttendanceStatus(
      String id, String status, String? motif) async {
    final db = await database;
    return db.update(
      'attendance',
      {'status': status, 'justification_motif': motif},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<List<Map<String, dynamic>>> getPendingAttendance() async {
    final db = await database;
    return db.query('attendance', where: 'is_synced = 0');
  }

  // ═══════════════════════════════════════════════════════════════════════
  // NOTES
  // ═══════════════════════════════════════════════════════════════════════
  static Future<void> upsertGrades(List<Map<String, dynamic>> grades) async {
    final db = await database;
    final batch = db.batch();
    for (final g in grades) {
      batch.insert(
          'grades',
          {
            'id': g['id'],
            'student_id': g['studentId'],
            'student_name': g['studentName'],
            'class_name': g['className'],
            'subject': g['subject'],
            'coefficient': g['coefficient'],
            'value': g['value'],
            'eval_type': g['evalType'],
            'trimestre': g['trimestre'],
            'date': g['date'],
            'comment': g['comment'],
            'is_synced': 1,
          },
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  static Future<List<Map<String, dynamic>>> getAllGrades() async {
    final db = await database;
    return db.query('grades');
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CLASSES
  // ═══════════════════════════════════════════════════════════════════════
  static Future<void> upsertClasses(List<Map<String, dynamic>> classes) async {
    final db = await database;
    final batch = db.batch();
    for (final c in classes) {
      batch.insert(
          'classes',
          {
            'id': c['id'],
            'name': c['name'],
            'level': c['level'],
            'cycle': c['cycle'],
            'capacity': c['capacity'] ?? 45,
            'is_synced': 1,
          },
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // FRAIS
  // ═══════════════════════════════════════════════════════════════════════
  static Future<void> upsertFees(List<Map<String, dynamic>> fees) async {
    final db = await database;
    final batch = db.batch();
    for (final f in fees) {
      batch.insert(
          'fees',
          {
            'id': f['id'],
            'type': f['type'],
            'label': f['label'],
            'montant': f['montant'],
            'trimestre': f['trimestre'],
            'class_level': f['classLevel'],
            'obligatoire': boolToInt(f['obligatoire'] ?? true),
            'date_echeance': f['dateEcheance'],
            'is_synced': 1,
          },
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PAIEMENTS
  // ═══════════════════════════════════════════════════════════════════════
  static Future<void> upsertPayments(
      List<Map<String, dynamic>> payments) async {
    final db = await database;
    final batch = db.batch();
    for (final p in payments) {
      batch.insert(
          'payments',
          {
            'id': p['id'],
            'student_id': p['studentId'],
            'student_name': p['studentName'],
            'class_name': p['className'],
            'fee_id': p['feeId'],
            'fee_label': p['feeLabel'],
            'montant': p['montant'],
            'method': p['method'],
            'status': p['status'],
            'date': p['date'],
            'operator_name': p['operatorName'],
            'phone_number': p['phoneNumber'],
            'transaction_id': p['transactionId'],
            'cheque_number': p['chequeNumber'],
            'receipt_number': p['receiptNumber'],
            'is_synced': 1,
          },
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  static Future<List<Map<String, dynamic>>> getUnsyncedPayments() async {
    final db = await database;
    return db.query('payments', where: 'is_synced = 0');
  }

  static Future<void> close() async => _db?.close();
}
