import '../network/api_client.dart';

class StudentsApiService {
  static Future<List<dynamic>> getAll({String? classId, String? search}) async {
    final response = await ApiClient.instance.get('/students', params: {
      if (classId != null) 'classId': classId,
      if (search != null) 'search': search,
    });
    return response.data as List<dynamic>;
  }

  static Future<Map<String, dynamic>> getById(String id) async {
    final response = await ApiClient.instance.get('/students/$id');
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getStats() async {
    final response = await ApiClient.instance.get('/students/stats');
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final response = await ApiClient.instance.post('/students', data: data);
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> update(
      String id, Map<String, dynamic> data) async {
    final response = await ApiClient.instance.put('/students/$id', data: data);
    return response.data as Map<String, dynamic>;
  }
}
