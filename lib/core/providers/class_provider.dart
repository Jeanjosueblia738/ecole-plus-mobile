import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/classes_api_service.dart';
import '../utils/school_year.dart';

// ─── Modèle Classe ────────────────────────────────────────────────────────
class SchoolClass {
  final String id;
  final String name; // ex: "3ème A"
  final String level; // ex: "3ème"
  final String cycle; // "Collège" | "Lycée"
  final int capacity;

  const SchoolClass({
    required this.id,
    required this.name,
    required this.level,
    required this.cycle,
    required this.capacity,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'level': level,
        'cycle': cycle,
        'capacity': capacity,
      };

  factory SchoolClass.fromJson(Map<String, dynamic> json) => SchoolClass(
        id: json['id'],
        name: json['name'],
        level: json['level'],
        cycle: json['cycle'],
        capacity: json['capacity'] ?? 50,
      );

  factory SchoolClass.fromApi(Map<String, dynamic> json) {
    final level = json['level']?.toString() ?? '';
    final cycle = kCollegeLevels.contains(level) ? 'Collège' : 'Lycée';
    return SchoolClass(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      level: level,
      cycle: cycle,
      capacity: (json['capacity'] as num?)?.toInt() ?? 50,
    );
  }
}

// Niveaux standard système ivoirien
const kCollegeLevels = ['6ème', '5ème', '4ème', '3ème'];
const kLyceeLevels = ['2nde', '1ère', 'Terminale'];
const kAllLevels = [...kCollegeLevels, ...kLyceeLevels];

// ─── Notifier ─────────────────────────────────────────────────────────────
class ClassNotifier extends StateNotifier<List<SchoolClass>> {
  static const _storageKey = 'school_classes';

  ClassNotifier() : super(const []);

  String? error;
  bool loading = false;

  Future<void> load() async {
    loading = true;
    error = null;
    try {
      final raw = await ClassesApiService.getAll(year: currentSchoolYear());
      state = raw
          .map((e) => SchoolClass.fromApi(Map<String, dynamic>.from(e as Map)))
          .toList();
      await _save();
    } catch (_) {
      error = 'Impossible de charger les classes';
      state = [];
    } finally {
      loading = false;
    }
  }

  Future<void> add(SchoolClass c) async {
    state = [...state, c];
    await _save();
  }

  Future<void> update(SchoolClass c) async {
    state = [
      for (final s in state)
        if (s.id == c.id) c else s
    ];
    await _save();
  }

  Future<void> remove(String id) async {
    state = state.where((c) => c.id != id).toList();
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _storageKey, jsonEncode(state.map((c) => c.toJson()).toList()));
  }
}

// ─── Providers ────────────────────────────────────────────────────────────
final classProvider = StateNotifierProvider<ClassNotifier, List<SchoolClass>>(
  (ref) => ClassNotifier(),
);

// Noms de classes pour dropdowns
final classNamesAdminProvider = Provider<List<String>>((ref) {
  return ref.watch(classProvider).map((c) => c.name).toList();
});

// Groupées par cycle
final classesByCycleProvider = Provider<Map<String, List<SchoolClass>>>((ref) {
  final classes = ref.watch(classProvider);
  final Map<String, List<SchoolClass>> grouped = {};
  for (final c in classes) {
    grouped.putIfAbsent(c.cycle, () => []).add(c);
  }
  return grouped;
});
