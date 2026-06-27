import '../network/api_client.dart';

class ParentApiService {
  // Récupérer les infos de l'enfant lié au parent
  // Le parent se connecte avec son email — l'API retourne son enfant
  static Future<Map<String, dynamic>> getMyChild() async {
    final response = await ApiClient.instance.get('/students/my-child');
    return response.data as Map<String, dynamic>;
  }

  // Notes de l'enfant
  static Future<Map<String, dynamic>> getChildGrades(
    String studentId, {
    String? trimestre,
  }) async {
    final response = await ApiClient.instance.get(
      '/grades/student/$studentId',
      params: {if (trimestre != null) 'trimestre': trimestre},
    );
    return response.data as Map<String, dynamic>;
  }

  // Absences de l'enfant
  static Future<Map<String, dynamic>> getChildAttendance(
      String studentId) async {
    final response = await ApiClient.instance.get(
      '/attendance/student/$studentId',
    );
    return response.data as Map<String, dynamic>;
  }

  // Situation financière de l'enfant
  static Future<Map<String, dynamic>> getChildFinance(String studentId) async {
    final response = await ApiClient.instance.get(
      '/finance/student/$studentId',
    );
    return response.data as Map<String, dynamic>;
  }
}
