import '../network/api_client.dart';

class ConseilApiService {
  /// Décisions du conseil de classe — élève
  static Future<List<dynamic>> getMy({String? year}) async {
    final response = await ApiClient.instance.get(
      '/conseil/my',
      params: {if (year != null) 'year': year},
    );
    final data = response.data;
    if (data is List) return data;
    return [];
  }

  /// Décisions du conseil — parent (enfant lié)
  static Future<List<dynamic>> getMyChild({
    String? studentId,
    String? year,
  }) async {
    final response = await ApiClient.instance.get(
      '/conseil/my-child',
      params: {
        if (studentId != null) 'studentId': studentId,
        if (year != null) 'year': year,
      },
    );
    final data = response.data;
    if (data is List) return data;
    return [];
  }

  /// Liste conseil pour une classe (staff)
  static Future<List<dynamic>> list({
    required String classId,
    required String trimestre,
    required String year,
  }) async {
    final response = await ApiClient.instance.get(
      '/conseil',
      params: {
        'classId': classId,
        'trimestre': trimestre,
        'year': year,
      },
    );
    final data = response.data;
    if (data is List) return data;
    return [];
  }

  /// Upsert décision conseil
  static Future<Map<String, dynamic>> upsert(Map<String, dynamic> data) async {
    final response = await ApiClient.instance.put('/conseil', data: data);
    return Map<String, dynamic>.from(response.data as Map);
  }
}
