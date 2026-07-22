import '../network/api_client.dart';

class ClassesApiService {
  static Future<List<dynamic>> getAll({
    String? year,
    bool includeInactive = false,
  }) async {
    final response = await ApiClient.instance.get(
      '/classes',
      params: {
        if (year != null) 'year': year,
        if (includeInactive) 'includeInactive': true,
      },
    );
    return response.data as List<dynamic>;
  }

  static Future<Map<String, dynamic>> getById(String id) async {
    final response = await ApiClient.instance.get('/classes/$id');
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final response = await ApiClient.instance.post('/classes', data: data);
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> update(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await ApiClient.instance.put('/classes/$id', data: data);
    return response.data as Map<String, dynamic>;
  }

  static Future<void> delete(String id) async {
    await ApiClient.instance.delete('/classes/$id');
  }
}
