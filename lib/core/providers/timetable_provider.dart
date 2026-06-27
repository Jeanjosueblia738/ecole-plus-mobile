import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/timetable/data/timetable_model.dart';

// ─── Notifier ─────────────────────────────────────────────────────────────
class TimetableNotifier extends StateNotifier<List<TimetableEntry>> {
  static const _key = 'timetable_entries';

  TimetableNotifier() : super(_defaultEntries());

  // EDT de démonstration — réaliste pour un lycée CI
  static List<TimetableEntry> _defaultEntries() => [
        // ── 3ème A ─────────────────────────────────────────────────────────
        const TimetableEntry(
            id: 't1',
            className: '3ème A',
            day: WeekDay.lundi,
            startTime: '07:30',
            endTime: '08:25',
            subject: 'Mathématiques',
            teacherName: 'M. Koné',
            room: 'S.12'),
        const TimetableEntry(
            id: 't2',
            className: '3ème A',
            day: WeekDay.lundi,
            startTime: '08:25',
            endTime: '09:20',
            subject: 'Français',
            teacherName: 'Mme Bamba',
            room: 'S.12'),
        const TimetableEntry(
            id: 't3',
            className: '3ème A',
            day: WeekDay.lundi,
            startTime: '10:30',
            endTime: '11:25',
            subject: 'SVT',
            teacherName: 'M. Touré',
            room: 'S.12'),
        const TimetableEntry(
            id: 't4',
            className: '3ème A',
            day: WeekDay.lundi,
            startTime: '11:25',
            endTime: '12:20',
            subject: 'Histoire-Géographie',
            teacherName: 'Mme Coulibaly',
            room: 'S.12'),
        const TimetableEntry(
            id: 't5',
            className: '3ème A',
            day: WeekDay.mardi,
            startTime: '07:30',
            endTime: '08:25',
            subject: 'Physique-Chimie',
            teacherName: 'M. Koné',
            room: 'Lab.1'),
        const TimetableEntry(
            id: 't6',
            className: '3ème A',
            day: WeekDay.mardi,
            startTime: '08:25',
            endTime: '09:20',
            subject: 'Anglais',
            teacherName: 'M. Diallo',
            room: 'S.12'),
        const TimetableEntry(
            id: 't7',
            className: '3ème A',
            day: WeekDay.mardi,
            startTime: '13:15',
            endTime: '14:10',
            subject: 'Mathématiques',
            teacherName: 'M. Koné',
            room: 'S.12'),
        const TimetableEntry(
            id: 't8',
            className: '3ème A',
            day: WeekDay.mercredi,
            startTime: '07:30',
            endTime: '08:25',
            subject: 'Français',
            teacherName: 'Mme Bamba',
            room: 'S.12'),
        const TimetableEntry(
            id: 't9',
            className: '3ème A',
            day: WeekDay.mercredi,
            startTime: '08:25',
            endTime: '09:20',
            subject: 'EPS',
            teacherName: 'M. Soro',
            room: 'Stade'),
        const TimetableEntry(
            id: 't10',
            className: '3ème A',
            day: WeekDay.jeudi,
            startTime: '07:30',
            endTime: '08:25',
            subject: 'Mathématiques',
            teacherName: 'M. Koné',
            room: 'S.12'),
        const TimetableEntry(
            id: 't11',
            className: '3ème A',
            day: WeekDay.jeudi,
            startTime: '08:25',
            endTime: '09:20',
            subject: 'SVT',
            teacherName: 'M. Touré',
            room: 'S.12'),
        const TimetableEntry(
            id: 't12',
            className: '3ème A',
            day: WeekDay.vendredi,
            startTime: '07:30',
            endTime: '08:25',
            subject: 'Anglais',
            teacherName: 'M. Diallo',
            room: 'S.12'),
        const TimetableEntry(
            id: 't13',
            className: '3ème A',
            day: WeekDay.vendredi,
            startTime: '08:25',
            endTime: '09:20',
            subject: 'Français',
            teacherName: 'Mme Bamba',
            room: 'S.12'),
        const TimetableEntry(
            id: 't14',
            className: '3ème A',
            day: WeekDay.samedi,
            startTime: '07:30',
            endTime: '08:25',
            subject: 'Histoire-Géographie',
            teacherName: 'Mme Coulibaly',
            room: 'S.12'),
        const TimetableEntry(
            id: 't15',
            className: '3ème A',
            day: WeekDay.samedi,
            startTime: '08:25',
            endTime: '09:20',
            subject: 'Physique-Chimie',
            teacherName: 'M. Koné',
            room: 'Lab.1'),
      ];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data != null) {
      final List decoded = jsonDecode(data);
      if (decoded.isNotEmpty) {
        state = decoded.map((e) => TimetableEntry.fromJson(e)).toList();
        return;
      }
    }
    // Garder les données par défaut si rien en storage
  }

  Future<void> addEntry(TimetableEntry entry) async {
    state = [...state, entry];
    await _save();
  }

  Future<void> removeEntry(String id) async {
    state = state.where((e) => e.id != id).toList();
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, jsonEncode(state.map((e) => e.toJson()).toList()));
  }
}

// ─── Provider global ──────────────────────────────────────────────────────
final timetableProvider =
    StateNotifierProvider<TimetableNotifier, List<TimetableEntry>>(
  (ref) => TimetableNotifier(),
);

// ─── Providers dérivés ────────────────────────────────────────────────────

// EDT d'une classe
final timetableByClassProvider =
    Provider.family<List<TimetableEntry>, String>((ref, className) {
  return ref
      .watch(timetableProvider)
      .where((e) => e.className == className)
      .toList()
    ..sort((a, b) {
      final dayComp = a.day.index.compareTo(b.day.index);
      if (dayComp != 0) return dayComp;
      return a.startTime.compareTo(b.startTime);
    });
});

// EDT d'un enseignant (ses cours dans toutes ses classes)
final timetableByTeacherProvider =
    Provider.family<List<TimetableEntry>, String>((ref, teacherName) {
  return ref
      .watch(timetableProvider)
      .where((e) => e.teacherName == teacherName)
      .toList()
    ..sort((a, b) {
      final dayComp = a.day.index.compareTo(b.day.index);
      if (dayComp != 0) return dayComp;
      return a.startTime.compareTo(b.startTime);
    });
});

// Cours du jour pour une classe
final todayTimetableProvider =
    Provider.family<List<TimetableEntry>, String>((ref, className) {
  final today = DateTime.now().weekday; // 1=Lundi ... 6=Samedi
  final todayEnum = today <= 6
      ? WeekDay.values[today - 1]
      : WeekDay.lundi; // Dimanche → affiche Lundi

  return ref
      .watch(timetableByClassProvider(className))
      .where((e) => e.day == todayEnum)
      .toList();
});
