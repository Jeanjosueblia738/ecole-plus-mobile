import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/student/data/student.dart';
import '../../features/grades/data/grade_model.dart';
import 'auth_provider.dart';
import 'student_provider.dart';
import 'attendance_provider.dart';
import 'grade_provider.dart';

class ParentProfile {
  final String id;
  final String fullName;
  final String phone;
  final List<String> childrenIds;

  const ParentProfile({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.childrenIds,
  });
}

/// Profil parent depuis la session auth (plus de mock).
final parentProfileProvider = Provider<ParentProfile>((ref) {
  final auth = ref.watch(authProvider);
  return ParentProfile(
    id: auth.userId ?? '',
    fullName: auth.fullName.isNotEmpty ? auth.fullName : (auth.email ?? 'Parent'),
    phone: auth.email ?? '',
    childrenIds: const [],
  );
});

final parentChildProvider = Provider<Student?>((ref) {
  final profile = ref.watch(parentProfileProvider);
  final students = ref.watch(studentProvider);
  if (students.isEmpty) return null;

  if (profile.childrenIds.isNotEmpty) {
    return students
        .where((s) => profile.childrenIds.contains(s.id))
        .firstOrNull;
  }
  return students.firstOrNull;
});

final parentChildAbsencesProvider = Provider<List<dynamic>>((ref) {
  final child = ref.watch(parentChildProvider);
  if (child == null) return [];
  return ref
      .watch(attendanceProvider)
      .where((a) => a.studentId == child.id)
      .toList();
});

final parentChildGradesProvider =
    Provider.family<List<Grade>, String>((ref, trimestre) {
  final child = ref.watch(parentChildProvider);
  if (child == null) return [];
  return ref
      .watch(gradeProvider)
      .where((g) => g.studentId == child.id && g.trimestre == trimestre)
      .toList();
});

final parentChildAverageProvider =
    Provider.family<double?, String>((ref, trimestre) {
  final grades = ref.watch(parentChildGradesProvider(trimestre));
  if (grades.isEmpty) return null;
  final coefTotal = grades.fold(0, (s, g) => s + g.coefficient);
  if (coefTotal == 0) return null;
  return grades.fold(0.0, (s, g) => s + g.value * g.coefficient) / coefTotal;
});

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
