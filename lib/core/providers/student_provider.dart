import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/student/data/student.dart';
import '../services/students_api_service.dart';

class StudentNotifier extends StateNotifier<List<Student>> {
  StudentNotifier() : super([]);

  bool loading = false;
  String? error;

  Future<void> load({String? classId, String? search}) async {
    loading = true;
    error = null;
    try {
      final raw = await StudentsApiService.getAll(
        classId: classId,
        search: search,
      );
      state = raw
          .map((e) => Student.fromApi(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      error = 'Impossible de charger les élèves';
      // Ne pas vider state si refresh échoue
    } finally {
      loading = false;
    }
  }

  Future<void> add(Student student) async {
    state = [...state, student];
  }

  Future<void> update(Student student) async {
    state = [
      for (final s in state)
        if (s.id == student.id) student else s,
    ];
  }

  Future<void> remove(String id) async {
    state = state.where((s) => s.id != id).toList();
  }

  List<Student> byClass(String className) {
    if (className.isEmpty || className == 'Toutes') return state;
    return state.where((s) => s.className == className).toList();
  }

  List<Student> byClassId(String classId) =>
      state.where((s) => s.classId == classId).toList();
}

final studentProvider = StateNotifierProvider<StudentNotifier, List<Student>>(
  (ref) => StudentNotifier(),
);

final studentsByClassProvider = Provider.family<List<Student>, String>(
  (ref, className) {
    final students = ref.watch(studentProvider);
    if (className == 'Toutes') return students;
    return students.where((s) => s.className == className).toList();
  },
);

final classNamesProvider = Provider<List<String>>((ref) {
  final students = ref.watch(studentProvider);
  final classes = students
      .map((s) => s.className)
      .where((n) => n.isNotEmpty)
      .toSet()
      .toList()
    ..sort();
  return ['Toutes', ...classes];
});
