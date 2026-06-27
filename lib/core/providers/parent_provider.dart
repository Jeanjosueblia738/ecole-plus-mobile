import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/student/data/student.dart';
import '../../features/grades/data/grade_model.dart';
import 'student_provider.dart';
import 'attendance_provider.dart';
import 'grade_provider.dart';

// ─── Profil parent simulé (remplacé par JWT en prod) ─────────────────────
class ParentProfile {
  final String id;
  final String fullName;
  final String phone;
  final List<String> childrenIds; // IDs des enfants liés

  const ParentProfile({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.childrenIds,
  });
}

const kMockParent = ParentProfile(
  id: 'parent_01',
  fullName: 'M. Kouassi Jean-Baptiste',
  phone: '+225 07 00 00 00',
  childrenIds: [], // sera résolu dynamiquement via le premier élève trouvé
);

// ─── Provider profil parent ───────────────────────────────────────────────
final parentProfileProvider = Provider<ParentProfile>((ref) => kMockParent);

// ─── Enfant du parent (premier élève si childrenIds vide en mode mock) ────
final parentChildProvider = Provider<Student?>((ref) {
  final profile = ref.watch(parentProfileProvider);
  final students = ref.watch(studentProvider);
  if (students.isEmpty) return null;

  // Mode prod : chercher par ID
  if (profile.childrenIds.isNotEmpty) {
    return students
        .where((s) => profile.childrenIds.contains(s.id))
        .firstOrNull;
  }
  // Mode mock : premier élève disponible
  return students.first;
});

// ─── Absences de l'enfant ─────────────────────────────────────────────────
final parentChildAbsencesProvider = Provider<List<dynamic>>((ref) {
  final child = ref.watch(parentChildProvider);
  if (child == null) return [];
  return ref
      .watch(attendanceProvider)
      .where((a) => a.studentId == child.id)
      .toList();
});

// ─── Notes de l'enfant pour un trimestre ─────────────────────────────────
final parentChildGradesProvider =
    Provider.family<List<Grade>, String>((ref, trimestre) {
  final child = ref.watch(parentChildProvider);
  if (child == null) return [];
  return ref
      .watch(gradeProvider)
      .where((g) => g.studentId == child.id && g.trimestre == trimestre)
      .toList();
});

// ─── Moyenne générale de l'enfant ─────────────────────────────────────────
final parentChildAverageProvider =
    Provider.family<double?, String>((ref, trimestre) {
  final grades = ref.watch(parentChildGradesProvider(trimestre));
  if (grades.isEmpty) return null;
  final coefTotal = grades.fold(0, (s, g) => s + g.coefficient);
  if (coefTotal == 0) return null;
  return grades.fold(0.0, (s, g) => s + g.value * g.coefficient) / coefTotal;
});

// ─── Stats résumées enfant ────────────────────────────────────────────────
class ChildStats {
  final int totalAbsences;
  final int absencesJustifiees;
  final int absencesEnAttente;
  final int absencesNonJustifiees;
  final double? moyenneTrimestre;

  const ChildStats({
    required this.totalAbsences,
    required this.absencesJustifiees,
    required this.absencesEnAttente,
    required this.absencesNonJustifiees,
    this.moyenneTrimestre,
  });
}

final childStatsProvider =
    Provider.family<ChildStats, String>((ref, trimestre) {
  final absences = ref.watch(parentChildAbsencesProvider);
  final moyenne = ref.watch(parentChildAverageProvider(trimestre));

  return ChildStats(
    totalAbsences: absences.length,
    absencesJustifiees: absences.where((a) => a.status == 'Justifiée').length,
    absencesEnAttente: absences.where((a) => a.status == 'En attente').length,
    absencesNonJustifiees: absences.where((a) => a.status == 'Absent').length,
    moyenneTrimestre: moyenne,
  );
});
