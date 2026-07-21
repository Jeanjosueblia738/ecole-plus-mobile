import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/timetable/data/timetable_model.dart';
import '../services/timetable_api_service.dart';
import '../utils/school_year.dart';

WeekDay _dayFromApi(dynamic raw) {
  final s = (raw?.toString() ?? 'LUNDI').toUpperCase();
  return switch (s) {
    'MARDI' => WeekDay.mardi,
    'MERCREDI' => WeekDay.mercredi,
    'JEUDI' => WeekDay.jeudi,
    'VENDREDI' => WeekDay.vendredi,
    'SAMEDI' => WeekDay.samedi,
    _ => WeekDay.lundi,
  };
}

TimetableEntry timetableEntryFromApi(
  Map<String, dynamic> json, {
  String? fallbackClassName,
  String? fallbackTeacherName,
}) {
  final teacher = json['teacher'] is Map
      ? Map<String, dynamic>.from(json['teacher'] as Map)
      : <String, dynamic>{};
  final clazz = json['class'] is Map
      ? Map<String, dynamic>.from(json['class'] as Map)
      : <String, dynamic>{};
  final teacherName = [
    teacher['firstName']?.toString() ?? '',
    teacher['lastName']?.toString() ?? '',
  ].where((p) => p.isNotEmpty).join(' ');

  return TimetableEntry(
    id: json['id']?.toString() ??
        DateTime.now().millisecondsSinceEpoch.toString(),
    className: clazz['name']?.toString() ??
        json['className']?.toString() ??
        fallbackClassName ??
        '',
    day: _dayFromApi(json['day']),
    startTime: json['startTime']?.toString() ?? '',
    endTime: json['endTime']?.toString() ?? '',
    subject: json['subject']?.toString() ?? '',
    teacherName: teacherName.isNotEmpty
        ? teacherName
        : (json['teacherName']?.toString() ?? fallbackTeacherName ?? ''),
    room: json['room']?.toString(),
  );
}

// ─── Notifier ─────────────────────────────────────────────────────────────
class TimetableNotifier extends StateNotifier<List<TimetableEntry>> {
  static const _key = 'timetable_entries';

  TimetableNotifier() : super(const []);

  bool loading = false;
  String? error;

  /// Charge depuis l'API (classe). Pas de données mock.
  Future<void> loadForClass(String classId, {String? className}) async {
    loading = true;
    error = null;
    try {
      final data = await TimetableApiService.getByClass(
        classId,
        year: currentSchoolYear(),
      );
      final slots = (data['slots'] as List?) ?? const [];
      state = slots
          .map((e) => timetableEntryFromApi(
                Map<String, dynamic>.from(e as Map),
                fallbackClassName: className,
              ))
          .toList();
    } catch (_) {
      error = 'Impossible de charger l\'emploi du temps';
      state = <TimetableEntry>[];
    } finally {
      loading = false;
    }
  }

  /// Charge depuis l'API (enseignant).
  Future<void> loadForTeacher(String teacherId,
      {String? teacherName}) async {
    loading = true;
    error = null;
    try {
      final slots = await TimetableApiService.getByTeacher(
        teacherId,
        year: currentSchoolYear(),
      );
      state = slots
          .map((e) => timetableEntryFromApi(
                Map<String, dynamic>.from(e as Map),
                fallbackTeacherName: teacherName,
              ))
          .toList();
    } catch (_) {
      error = 'Impossible de charger l\'emploi du temps';
      state = <TimetableEntry>[];
    } finally {
      loading = false;
    }
  }

  /// Fallback local (édition offline / legacy). Liste vide si rien en cache.
  Future<void> load() async {
    loading = true;
    error = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_key);
      if (data != null) {
        final List decoded = jsonDecode(data);
        state = decoded.map((e) => TimetableEntry.fromJson(e)).toList();
      } else {
        state = <TimetableEntry>[];
      }
    } catch (_) {
      error = 'Impossible de charger l\'emploi du temps';
      state = <TimetableEntry>[];
    } finally {
      loading = false;
    }
  }

  /// Ajoute un créneau. Si [classId] est fourni, tente POST `/timetable`.
  /// Retourne `true` si synchronisé serveur, `false` si local seulement.
  Future<bool> addEntry(TimetableEntry entry, {String? classId}) async {
    if (classId != null && classId.isNotEmpty) {
      try {
        final dayApi = switch (entry.day) {
          WeekDay.lundi => 'LUNDI',
          WeekDay.mardi => 'MARDI',
          WeekDay.mercredi => 'MERCREDI',
          WeekDay.jeudi => 'JEUDI',
          WeekDay.vendredi => 'VENDREDI',
          WeekDay.samedi => 'SAMEDI',
        };
        final res = await TimetableApiService.create({
          'classId': classId,
          'subject': entry.subject,
          'day': dayApi,
          'startTime': entry.startTime,
          'endTime': entry.endTime,
          'year': currentSchoolYear(),
          if (entry.room != null && entry.room!.isNotEmpty) 'room': entry.room,
        });
        final saved = timetableEntryFromApi(
          Map<String, dynamic>.from(res),
          fallbackClassName: entry.className,
          fallbackTeacherName: entry.teacherName,
        );
        state = [...state, saved];
        return true;
      } catch (_) {
        // fallback local ci-dessous
      }
    }
    state = [...state, entry];
    await _save();
    return false;
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
