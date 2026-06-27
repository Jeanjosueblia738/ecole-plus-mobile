import '../network/api_client.dart';

class StudentApiService {
  // Profil de l'élève connecté (via JWT)
  static Future<Map<String, dynamic>> getMyProfile() async {
    final response = await ApiClient.instance.get('/students/my-profile');
    return response.data as Map<String, dynamic>;
  }

  // Notes de l'élève
  static Future<List<dynamic>> getMyGrades({String? trimestre}) async {
    final response = await ApiClient.instance.get(
      '/grades/student/me',
      params: {if (trimestre != null) 'trimestre': trimestre},
    );
    return response.data as List<dynamic>;
  }

  // Absences de l'élève
  static Future<Map<String, dynamic>> getMyAttendance() async {
    final response = await ApiClient.instance.get('/attendance/student/me');
    return response.data as Map<String, dynamic>;
  }

  // Emploi du temps de l'élève
  static Future<List<dynamic>> getMyTimetable() async {
    final response = await ApiClient.instance.get('/timetable/my-class');
    return response.data as List<dynamic>;
  }

  // Situation financière
  static Future<Map<String, dynamic>> getMyFinance() async {
    final response = await ApiClient.instance.get('/finance/student/me');
    return response.data as Map<String, dynamic>;
  }
}
