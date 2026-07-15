import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/student/data/student.dart';
import 'student_provider.dart';

class StudentSessionNotifier extends StateNotifier<Student?> {
  StudentSessionNotifier() : super(null);

  void setStudent(Student student) => state = student;
  void clear() => state = null;
}

final studentSessionProvider =
    StateNotifierProvider<StudentSessionNotifier, Student?>(
  (ref) => StudentSessionNotifier(),
);

/// Élève connecté — pas de mock. Null si aucune session/données.
final currentStudentProvider = Provider<Student?>((ref) {
  final session = ref.watch(studentSessionProvider);
  if (session != null) return session;

  final students = ref.watch(studentProvider);
  if (students.isNotEmpty) return students.first;

  return null;
});
