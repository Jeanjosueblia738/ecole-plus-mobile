import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/grades/data/grade_model.dart';
import '../../features/student/data/student.dart';

// ─── Notifier ─────────────────────────────────────────────────────────────
class GradeNotifier extends StateNotifier<List<Grade>> {
  static const _storageKey = 'grades';

  GradeNotifier() : super([]);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);
    if (data != null) {
      final List decoded = jsonDecode(data);
      state = decoded.map((e) => Grade.fromJson(e)).toList();
    }
  }

  Future<void> addGrade(Grade grade) async {
    state = [...state, grade];
    await _save();
  }

  Future<void> addGrades(List<Grade> grades) async {
    state = [...state, ...grades];
    await _save();
  }

  Future<void> deleteGrade(String id) async {
    state = state.where((g) => g.id != id).toList();
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _storageKey, jsonEncode(state.map((g) => g.toJson()).toList()));
  }
}

// ─── Provider global ──────────────────────────────────────────────────────
final gradeProvider = StateNotifierProvider<GradeNotifier, List<Grade>>(
  (ref) => GradeNotifier(),
);

// ─── Notes d'un élève pour un trimestre ───────────────────────────────────
final gradesByStudentProvider =
    Provider.family<List<Grade>, ({String studentId, String trimestre})>(
  (ref, args) => ref
      .watch(gradeProvider)
      .where(
          (g) => g.studentId == args.studentId && g.trimestre == args.trimestre)
      .toList(),
);

// ─── Bulletin calculé pour un élève ───────────────────────────────────────
final bulletinProvider = Provider.family<Bulletin?,
    ({String studentId, String trimestre, List<Student> classmates})>(
  (ref, args) {
    final grades = ref
        .watch(gradeProvider)
        .where((g) =>
            g.studentId == args.studentId && g.trimestre == args.trimestre)
        .toList();

    if (grades.isEmpty) return null;

    // Grouper par matière
    final Map<String, List<Grade>> bySubject = {};
    for (final g in grades) {
      bySubject.putIfAbsent(g.subject, () => []).add(g);
    }

    // Calculer SubjectResult pour chaque matière
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

    // Calcul du rang parmi les élèves de la classe
    final allGrades = ref.watch(gradeProvider);
    final classMoyennes = <String, double>{};

    for (final student in args.classmates) {
      final sGrades = allGrades
          .where(
              (g) => g.studentId == student.id && g.trimestre == args.trimestre)
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
      studentName: student.fullName,
      className: student.className,
      trimestre: args.trimestre,
      results: results,
      rang: rang > 0 ? rang : 1,
      totalEleves: classMoyennes.length,
    );
  },
);

// ─── Stats classe par matière ─────────────────────────────────────────────
final classStatsProvider = Provider.family<Map<String, double>,
    ({String className, String trimestre})>(
  (ref, args) {
    final grades = ref
        .watch(gradeProvider)
        .where((g) =>
            g.className == args.className && g.trimestre == args.trimestre)
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
