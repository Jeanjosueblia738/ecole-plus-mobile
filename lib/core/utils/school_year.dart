import 'package:shared_preferences/shared_preferences.dart';
import '../services/academic_year_api_service.dart';

const _selectedYearKey = 'ecole_selected_year';

String? _selectedYearCache;
bool _serverSynced = false;

/// Année scolaire CIV calendaire (sept → août).
String calendarSchoolYear([DateTime? now]) {
  final d = now ?? DateTime.now();
  final start = d.month >= 9 ? d.year : d.year - 1;
  return '$start-${start + 1}';
}

bool hasSelectedSchoolYearPref() => _selectedYearCache != null;

/// Charge le cookie/prefs année sélectionnée en cache mémoire.
Future<void> initSelectedSchoolYear() async {
  final prefs = await SharedPreferences.getInstance();
  final selected = prefs.getString(_selectedYearKey);
  if (selected != null && RegExp(r'^\d{4}-\d{4}$').hasMatch(selected)) {
    _selectedYearCache = selected;
  }
}

/// Synchronise avec GET /academic-years/current si aucune préférence valide.
Future<String> syncSchoolYearFromServer({bool force = false}) async {
  await initSelectedSchoolYear();
  if (_serverSynced && !force && _selectedYearCache != null) {
    return currentSchoolYear();
  }
  try {
    final current = await AcademicYearApiService.getCurrent();
    final label = current['label'] as String?;
    if (label != null && RegExp(r'^\d{4}-\d{4}$').hasMatch(label)) {
      if (_selectedYearCache == null || force) {
        await setSelectedSchoolYear(label);
      }
      _serverSynced = true;
      return currentSchoolYear();
    }
  } catch (_) {
    /* keep local / calendar */
  }
  _serverSynced = true;
  return currentSchoolYear();
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
