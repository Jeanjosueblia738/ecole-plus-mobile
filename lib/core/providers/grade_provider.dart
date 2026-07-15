import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/grades/data/grade_model.dart';
import '../../features/student/data/student.dart';
import '../services/grades_api_service.dart';

// ─── Notifier (source = API) ───────────────────────────────────────────────
class GradeNotifier extends StateNotifier<List<Grade>> {
  GradeNotifier() : super([]);

  bool loading = false;
  String? error;

  Future<void> loadForStudent(
    String studentId, {
    String? trimestre,
    String studentName = '',
    String className = '',
  }) async {
    loading = true;
    error = null;
    try {
      final apiT = trimestre != null ? apiTrimestre(trimestre) : null;
      final data = await GradesApiService.getByStudent(
        studentId,
        trimestre: apiT,
      );
      final raw = (data['grades'] as List?) ?? [];
      final incoming = raw
          .map((e) => Grade.fromApi(
                Map<String, dynamic>.from(e as Map),
                studentName: studentName,
                className: className,
              ))
          .toList();

      final displayT = trimestre != null ? displayTrimestre(trimestre) : null;
      state = [
        ...state.where((g) {
          if (g.studentId != studentId) return true;
          if (displayT == null) return false;
          return g.trimestre != displayT;
        }),
        ...incoming,
      ];
    } catch (e) {
      error = 'Impossible de charger les notes';
    } finally {
      loading = false;
    }
  }

  /// Charge les notes d'une classe (pour rang bulletin).
  Future<void> loadForClass(
    String classId,
    String trimestre, {
    required List<Student> classmates,
  }) async {
    loading = true;
    error = null;
    try {
      final apiT = apiTrimestre(trimestre);
      final rows = await GradesApiService.getByClass(classId, apiT);
      final displayT = displayTrimestre(trimestre);
      final byId = {for (final s in classmates) s.id: s};
      final incoming = <Grade>[];

      for (final row in rows) {
        final map = Map<String, dynamic>.from(row as Map);
        final studentMap = map['student'] is Map
            ? Map<String, dynamic>.from(map['student'] as Map)
            : <String, dynamic>{};
        final sid = studentMap['id']?.toString() ??
            map['studentId']?.toString() ??
            '';
        final mate = byId[sid];
        final name = mate?.fullName ??
            '${studentMap['firstName'] ?? ''} ${studentMap['lastName'] ?? ''}'
                .trim();
        final className = mate?.className ?? '';
        final grades = (map['grades'] as List?) ?? [];
        for (final g in grades) {
          incoming.add(Grade.fromApi(
            Map<String, dynamic>.from(g as Map),
            studentName: name,
            className: className,
          ));
        }
      }

      state = [
        ...state.where((g) {
          final inClass = classmates.any((s) => s.id == g.studentId);
          if (!inClass) return true;
          return g.trimestre != displayT;
        }),
        ...incoming,
      ];
    } catch (e) {
      error = 'Impossible de charger les notes de classe';
    } finally {
      loading = false;
    }
  }

  Future<void> addGrade(Grade grade) async {
    state = [...state, grade];
  }

  Future<void> addGrades(List<Grade> grades) async {
    state = [...state, ...grades];
  }

  Future<void> deleteGrade(String id) async {
    state = state.where((g) => g.id != id).toList();
  }
}

// ─── Provider global ──────────────────────────────────────────────────────
final gradeProvider = StateNotifierProvider<GradeNotifier, List<Grade>>(
  (ref) => GradeNotifier(),
);

// ─── Notes d'un élève pour un trimestre ───────────────────────────────────
final gradesByStudentProvider =
    Provider.family<List<Grade>, ({String studentId, String trimestre})>(
  (ref, args) {
    final displayT = displayTrimestre(args.trimestre);
    return ref
        .watch(gradeProvider)
        .where(
            (g) => g.studentId == args.studentId && g.trimestre == displayT)
        .toList();
  },
);

// ─── Bulletin calculé pour un élève ───────────────────────────────────────
final bulletinProvider = Provider.family<Bulletin?,
    ({String studentId, String trimestre, List<Student> classmates})>(
  (ref, args) {
    final displayT = displayTrimestre(args.trimestre);
    final grades = ref
        .watch(gradeProvider)
        .where(
            (g) => g.studentId == args.studentId && g.trimestre == displayT)
        .toList();

    if (grades.isEmpty) return null;

    final Map<String, List<Grade>> bySubject = {};
    for (final g in grades) {
      bySubject.putIfAbsent(g.subject, () => []).add(g);
    }

    final results = bySubject.entries.map((e) {
      final subjectGrades = e.value;
      final avg =
          subjectGrades.fold(0.0, (s, g) => s + g.value) / subjectGrades.length;
      return SubjectResult(
        subject: e.key,
        coefficient: subjectGrades.first.coefficient,
        moyenne: avg,
        grades: subjectGrades,
      );
    }).toList()
      ..sort((a, b) => a.subject.compareTo(b.subject));

    final allGrades = ref.watch(gradeProvider);
    final classMoyennes = <String, double>{};

    for (final student in args.classmates) {
      final sGrades = allGrades
          .where(
              (g) => g.studentId == student.id && g.trimestre == displayT)
          .toList();
      if (sGrades.isNotEmpty) {
        final coefTotal = sGrades.fold(0, (s, g) => s + g.coefficient);
        final pointsTotal =
            sGrades.fold(0.0, (s, g) => s + g.value * g.coefficient);
        classMoyennes[student.id] = coefTotal > 0 ? pointsTotal / coefTotal : 0;
      }
    }

    final sortedMoyennes = classMoyennes.values.toList()
      ..sort((a, b) => b.compareTo(a));

    final coefTotal = results.fold(0, (s, r) => s + r.coefficient);
    final myMoyenne = coefTotal > 0
        ? results.fold(0.0, (s, r) => s + r.moyennePonderee) / coefTotal
        : 0.0;

    final rang = sortedMoyennes.indexWhere((m) => m <= myMoyenne) + 1;

    final student = args.classmates.firstWhere((s) => s.id == args.studentId,
        orElse: () =>
            Student(id: '', fullName: '', className: '', parentPhone: ''));

    return Bulletin(
      studentId: args.studentId,
      studentName: student.fullName.isNotEmpty
          ? student.fullName
          : (grades.first.studentName),
      className: student.className.isNotEmpty
          ? student.className
          : grades.first.className,
      trimestre: displayT,
      results: results,
      rang: rang > 0 ? rang : 1,
      totalEleves: classMoyennes.isEmpty ? 1 : classMoyennes.length,
    );
  },
);

// ─── Stats classe par matière ─────────────────────────────────────────────
final classStatsProvider = Provider.family<Map<String, double>,
    ({String className, String trimestre})>(
  (ref, args) {
    final displayT = displayTrimestre(args.trimestre);
    final grades = ref
        .watch(gradeProvider)
        .where((g) =>
            g.className == args.className && g.trimestre == displayT)
        .toList();

    final Map<String, List<double>> bySubject = {};
    for (final g in grades) {
      bySubject.putIfAbsent(g.subject, () => []).add(g.value);
    }

    return {
      for (final e in bySubject.entries)
        e.key: e.value.fold(0.0, (s, v) => s + v) / e.value.length,
    };
  },
);
