import '../network/api_client.dart';

class ExamsApiService {
  /// Examens / compositions — élève ou enseignant
  static Future<List<dynamic>> getMy({String? year}) async {
    final response = await ApiClient.instance.get(
      '/examens/my',
      params: {if (year != null) 'year': year},
    );
    return response.data as List<dynamic>;
  }

  /// Examens de l'enfant — parent
  static Future<List<dynamic>> getMyChild({
    String? studentId,
    String? year,
  }) async {
    final response = await ApiClient.instance.get(
      '/examens/my-child',
      params: {
        if (studentId != null) 'studentId': studentId,
        if (year != null) 'year': year,
      },
    );
    return response.data as List<dynamic>;
  }
}
