import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/grades/data/grade_model.dart';
import 'auth_provider.dart';
import 'grade_provider.dart';
import 'attendance_provider.dart';
import 'student_provider.dart';

class TeacherProfile {
  final String id;
  final String fullName;
  final List<String> assignedClasses;
  final List<String> subjects;

  const TeacherProfile({
    required this.id,
    required this.fullName,
    required this.assignedClasses,
    required this.subjects,
  });
}

/// Profil enseignant depuis la session auth (plus de mock Koné).
final teacherProfileProvider = Provider<TeacherProfile>((ref) {
  final auth = ref.watch(authProvider);
  return TeacherProfile(
    id: auth.userId ?? '',
    fullName: auth.fullName.isNotEmpty ? auth.fullName : (auth.email ?? 'Enseignant'),
    assignedClasses: const [],
    subjects: const [],
  );
});

final teacherClassesProvider = Provider<List<String>>((ref) {
  return ref.watch(teacherProfileProvider).assignedClasses;
});

final teacherSubjectsProvider = Provider<List<String>>((ref) {
  return ref.watch(teacherProfileProvider).subjects;
});

class ClassStats {
  final String className;
  final int studentCount;
  final int absenceCount;
  final double? moyenneClasse;

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

final teacherGradesProvider = Provider<List<Grade>>((ref) {
  final profile = ref.watch(teacherProfileProvider);
  return ref
      .watch(gradeProvider)
      .where((g) =>
          profile.assignedClasses.contains(g.className) &&
          profile.subjects.contains(g.subject))
      .toList();
});
