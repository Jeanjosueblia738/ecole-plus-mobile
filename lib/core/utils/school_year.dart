import 'package:shared_preferences/shared_preferences.dart';

const _selectedYearKey = 'ecole_selected_year';

String? _selectedYearCache;

/// Année scolaire CIV calendaire (sept → août).
String calendarSchoolYear([DateTime? now]) {
  final d = now ?? DateTime.now();
  final start = d.month >= 9 ? d.year : d.year - 1;
  return '$start-${start + 1}';
}

/// Charge le cookie/prefs année sélectionnée en cache mémoire.
Future<void> initSelectedSchoolYear() async {
  final prefs = await SharedPreferences.getInstance();
  final selected = prefs.getString(_selectedYearKey);
  if (selected != null && RegExp(r'^\d{4}-\d{4}$').hasMatch(selected)) {
    _selectedYearCache = selected;
  }
}

Future<void> setSelectedSchoolYear(String label) async {
  if (!RegExp(r'^\d{4}-\d{4}$').hasMatch(label)) return;
  _selectedYearCache = label;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_selectedYearKey, label);
}

/// Année active UI : sélection prefs si présente, sinon calendrier.
String currentSchoolYear([DateTime? now]) {
  final cached = _selectedYearCache;
  if (cached != null && RegExp(r'^\d{4}-\d{4}$').hasMatch(cached)) {
    return cached;
  }
  return calendarSchoolYear(now);
}
