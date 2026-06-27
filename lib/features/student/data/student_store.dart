import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'student.dart';

class StudentStore {
  static const _storageKey = 'students';
  static List<Student> _students = [];

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);

    if (data != null) {
      final List decoded = jsonDecode(data);
      _students = decoded.map((e) => Student.fromJson(e)).toList();
    }
  }

  static List<Student> getStudents({String? className}) {
    if (className == null) return List.unmodifiable(_students);
    return _students.where((s) => s.className == className).toList();
  }

  static Future<void> add(Student student) async {
    _students.add(student);
    await _save();
  }

  static Future<void> update(Student student) async {
    final index = _students.indexWhere((s) => s.id == student.id);
    if (index != -1) {
      _students[index] = student;
      await _save();
    }
  }

  static Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_students.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }
}
