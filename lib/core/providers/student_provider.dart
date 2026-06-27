import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/student/data/student.dart';

// ─── Notifier ─────────────────────────────────────────────────────────────
class StudentNotifier extends StateNotifier<List<Student>> {
  static const _storageKey = 'students';

  StudentNotifier() : super([]);

  // Chargement initial depuis SharedPreferences
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);
    if (data != null) {
      final List decoded = jsonDecode(data);
      state = decoded.map((e) => Student.fromJson(e)).toList();
    }
  }

  Future<void> add(Student student) async {
    state = [...state, student];
    await _save();
  }

  Future<void> update(Student student) async {
    state = [
      for (final s in state)
        if (s.id == student.id) student else s,
    ];
    await _save();
  }

  Future<void> remove(String id) async {
    state = state.where((s) => s.id != id).toList();
    await _save();
  }

  // Filtre par classe — méthode utilitaire
  List<Student> byClass(String className) =>
      state.where((s) => s.className == className).toList();

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(state.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }
}

// ─── Provider global ──────────────────────────────────────────────────────
final studentProvider = StateNotifierProvider<StudentNotifier, List<Student>>(
  (ref) => StudentNotifier(),
);

// ─── Provider dérivé : liste filtrée par classe ───────────────────────────
final studentsByClassProvider = Provider.family<List<Student>, String>(
  (ref, className) {
    final students = ref.watch(studentProvider);
    if (className == 'Toutes') return students;
    return students.where((s) => s.className == className).toList();
  },
);

// ─── Provider dérivé : classes distinctes ────────────────────────────────
final classNamesProvider = Provider<List<String>>((ref) {
  final students = ref.watch(studentProvider);
  final classes = students.map((s) => s.className).toSet().toList()..sort();
  return ['Toutes', ...classes];
});
