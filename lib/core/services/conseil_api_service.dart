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
}
