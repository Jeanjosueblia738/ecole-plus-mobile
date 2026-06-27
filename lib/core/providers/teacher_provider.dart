import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/grades/data/grade_model.dart';
import 'grade_provider.dart';
import 'attendance_provider.dart';
import 'student_provider.dart';

// ─── Profil enseignant (simulé — sera remplacé par API) ───────────────────
class TeacherProfile {
  final String id;
  final String fullName;
  final List<String> assignedClasses; // classes dont il est responsable
  final List<String> subjects; // matières qu'il enseigne

  const TeacherProfile({
    required this.id,
    required this.fullName,
    required this.assignedClasses,
    required this.subjects,
  });
}

// Profil simulé — en prod, viendra du JWT après login réel
const kMockTeacher = TeacherProfile(
  id: 'teacher_01',
  fullName: 'M. Koné Dramane',
  assignedClasses: ['3ème A', '2nde A', '1ère A'],
  subjects: ['Mathématiques', 'Physique-Chimie'],
);

// ─── Provider profil enseignant ───────────────────────────────────────────
final teacherProfileProvider = Provider<TeacherProfile>((ref) {
  return kMockTeacher;
});

// ─── Classes de l'enseignant ──────────────────────────────────────────────
final teacherClassesProvider = Provider<List<String>>((ref) {
  return ref.watch(teacherProfileProvider).assignedClasses;
});

// ─── Matières de l'enseignant ─────────────────────────────────────────────
final teacherSubjectsProvider = Provider<List<String>>((ref) {
  return ref.watch(teacherProfileProvider).subjects;
});

// ─── Stats par classe pour l'enseignant ───────────────────────────────────
class ClassStats {
  final String className;
  final int studentCount;
  final int absenceCount;
  final double? moyenneClasse; // null si aucune note saisie

  const ClassStats({
    required this.className,
    required this.studentCount,
    required this.absenceCount,
    this.moyenneClasse,
  });
}

final teacherClassStatsProvider = Provider<List<ClassStats>>((ref) {
  final classes = ref.watch(teacherClassesProvider);
  final students = ref.watch(studentProvider);
  final absences = ref.watch(attendanceProvider);
  final grades = ref.watch(gradeProvider);

  return classes.map((className) {
    final classStudents =
        students.where((s) => s.className == className).length;
    final classAbsences =
        absences.where((a) => a.className == className).length;

    final classGrades = grades.where((g) => g.className == className).toList();
    final moyenne = classGrades.isEmpty
        ? null
        : classGrades.fold(0.0, (s, g) => s + g.value) / classGrades.length;

    return ClassStats(
      className: className,
      studentCount: classStudents,
      absenceCount: classAbsences,
      moyenneClasse: moyenne,
    );
  }).toList();
});

// ─── Notes saisies par l'enseignant (ses matières dans ses classes) ────────
final teacherGradesProvider = Provider<List<Grade>>((ref) {
  final profile = ref.watch(teacherProfileProvider);
  return ref
      .watch(gradeProvider)
      .where((g) =>
          profile.assignedClasses.contains(g.className) &&
          profile.subjects.contains(g.subject))
      .toList();
});
