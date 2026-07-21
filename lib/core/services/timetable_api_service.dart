import '../network/api_client.dart';
import '../utils/school_year.dart';

class TimetableApiService {
  // Emploi du temps d'une classe — retourne { slots: [], byDay: { LUNDI: [], ... } }
  static Future<Map<String, dynamic>> getByClass(
    String classId, {
    String? year,
  }) async {
    final response = await ApiClient.instance.get(
      '/timetable/class/$classId',
      params: {'year': year ?? currentSchoolYear()},
    );
    return response.data as Map<String, dynamic>;
  }

  // Emploi du temps enseignant — liste de créneaux
  static Future<List<dynamic>> getByTeacher(
    String teacherId, {
    String? year,
  }) async {
    final response = await ApiClient.instance.get(
      '/timetable/teacher/$teacherId',
      params: {'year': year ?? currentSchoolYear()},
    );
    final data = response.data;
    if (data is List) return data;
    if (data is Map && data['slots'] is List) {
      return data['slots'] as List<dynamic>;
    }
    return const [];
  }

  static Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final response = await ApiClient.instance.post('/timetable', data: data);
    return response.data as Map<String, dynamic>;
  }
}
