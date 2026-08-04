import '../network/api_client.dart';

class DisciplineApiService {
  static Future<List<dynamic>> list({
    String? classId,
    String? studentId,
    String? year,
    String? type,
  }) async {
    final response = await ApiClient.instance.get(
      '/discipline',
      params: {
        if (classId != null && classId.isNotEmpty) 'classId': classId,
        if (studentId != null && studentId.isNotEmpty) 'studentId': studentId,
        if (year != null && year.isNotEmpty) 'year': year,
        if (type != null && type.isNotEmpty) 'type': type,
      },
    );
    final data = response.data;
    if (data is List) return data;
    return [];
  }

  static Future<Map<String, dynamic>> stats({String? year}) async {
    final response = await ApiClient.instance.get(
      '/discipline/stats',
      params: {if (year != null && year.isNotEmpty) 'year': year},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  static Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final response =
        await ApiClient.instance.post('/discipline', data: data);
    return Map<String, dynamic>.from(response.data as Map);
  }

  static Future<void> delete(String id) async {
    await ApiClient.instance.delete('/discipline/$id');
  }

  static Future<List<dynamic>> byStudent(String studentId) async {
    final response =
        await ApiClient.instance.get('/discipline/student/$studentId');
    final data = response.data;
    if (data is List) return data;
    return [];
  }

  static Future<List<dynamic>> mySanctions() async {
    final response = await ApiClient.instance.get('/discipline/student/me');
    final data = response.data;
    if (data is List) return data;
    return [];
  }
}
