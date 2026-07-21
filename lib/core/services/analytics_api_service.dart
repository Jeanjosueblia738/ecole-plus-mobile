import '../network/api_client.dart';

class AnalyticsApiService {
  static Future<Map<String, dynamic>> getDropoutRisk({
    String? classId,
    String? minLevel,
  }) async {
    final response = await ApiClient.instance.get(
      '/analytics/dropout-risk',
      params: {
        if (classId != null && classId.isNotEmpty) 'classId': classId,
        if (minLevel != null && minLevel.isNotEmpty) 'minLevel': minLevel,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getStudentDropoutRisk(
      String studentId) async {
    final response =
        await ApiClient.instance.get('/analytics/dropout-risk/$studentId');
    return response.data as Map<String, dynamic>;
  }

  /// Progression scolaire — élève connecté
  static Future<Map<String, dynamic>> getMyProgress() async {
    final response = await ApiClient.instance.get('/analytics/my-progress');
    return response.data as Map<String, dynamic>;
  }

  /// Progression de l'enfant — parent
  static Future<Map<String, dynamic>> getMyChildProgress({
    String? studentId,
  }) async {
    final response = await ApiClient.instance.get(
      '/analytics/my-child-progress',
      params: {if (studentId != null) 'studentId': studentId},
    );
    return response.data as Map<String, dynamic>;
  }
}
