import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/student/data/student.dart';
import 'student_provider.dart';

// Session eleve connecte
// En prod : viendra du JWT apres login reel
// En mode simulation : eleve mock integre

class StudentSessionNotifier extends StateNotifier<Student?> {
  StudentSessionNotifier() : super(null);

  void setStudent(Student student) => state = student;
  void clear() => state = null;
}

final studentSessionProvider =
    StateNotifierProvider<StudentSessionNotifier, Student?>(
  (ref) => StudentSessionNotifier(),
);

// Eleve mock par defaut — affiche toujours quelque chose meme sans donnees
final _mockStudent = Student(
  id: 'student_mock_01',
  fullName: 'Kouame Jean-Baptiste',
  className: '3eme A',
  parentPhone: '+225 07 00 00 00',
);

// Provider qui resout l'eleve connecte
final currentStudentProvider = Provider<Student?>((ref) {
  // 1. Session explicite (apres vrai login)
  final session = ref.watch(studentSessionProvider);
  if (session != null) return session;

  // 2. Premier eleve de la liste (SharedPreferences)
  final students = ref.watch(studentProvider);
  if (students.isNotEmpty) return students.first;

  // 3. Fallback mock — toujours visible meme a vide
  return _mockStudent;
});
