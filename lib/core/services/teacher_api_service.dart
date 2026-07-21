import '../network/api_client.dart';
import '../utils/school_year.dart';

class TeacherApiService {
  // Profil de l'enseignant connecté
  static Future<Map<String, dynamic>> getMyProfile() async {
    final response = await ApiClient.instance.get('/teachers/me');
    return response.data as Map<String, dynamic>;
  }

  /// Mise à jour du profil enseignant (prénom, nom, téléphone, photo)
  static Future<Map<String, dynamic>> updateMyProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? photoUrl,
  }) async {
    final response = await ApiClient.instance.patch('/teachers/me', data: {
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (phone != null) 'phone': phone,
      if (photoUrl != null) 'photoUrl': photoUrl,
    });
    return response.data as Map<String, dynamic>;
  }

  // Classes de l'enseignant (1 → N)
  static Future<List<dynamic>> getMyClasses({String? year}) async {
    final response = await ApiClient.instance.get(
      '/teachers/my-classes',
      params: {'year': year ?? currentSchoolYear()},
    );
    return response.data as List<dynamic>;
  }

  // Élèves d'une classe
  static Future<List<dynamic>> getClassStudents(String classId) async {
    final response =
        await ApiClient.instance.get('/students', params: {'classId': classId});
    return response.data as List<dynamic>;
  }

  // Stats globales enseignant
  static Future<Map<String, dynamic>> getStats({String? year}) async {
    final response = await ApiClient.instance.get(
      '/teachers/my-stats',
      params: {'year': year ?? currentSchoolYear()},
    );
    return response.data as Map<String, dynamic>;
  }

  // Notes saisies par l'enseignant
  static Future<List<dynamic>> getMyGrades(
      {String? classId, String? trimestre}) async {
    final response = await ApiClient.instance.get(
        '/grades/class/${classId ?? ""}',
        params: {if (trimestre != null) 'trimestre': trimestre});
    return response.data as List<dynamic>;
  }

  // Absences d'une classe
  static Future<List<dynamic>> getClassAttendance(String classId,
      {String? date}) async {
    final response = await ApiClient.instance.get('/attendance/class/$classId',
        params: {if (date != null) 'date': date});
    return response.data as List<dynamic>;
  }
}
