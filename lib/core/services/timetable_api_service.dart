import '../network/api_client.dart';

class TimetableApiService {
  // Emploi du temps d'une classe — retourne { slots: [], byDay: { LUNDI: [], ... } }
  static Future<Map<String, dynamic>> getByClass(String classId) async {
    final response = await ApiClient.instance.get('/timetable/class/$classId');
    return response.data as Map<String, dynamic>;
  }

  // Emploi du temps enseignant
  static Future<Map<String, dynamic>> getByTeacher(String teacherId) async {
    final response =
        await ApiClient.instance.get('/timetable/teacher/$teacherId');
    return response.data as Map<String, dynamic>;
  }
}
