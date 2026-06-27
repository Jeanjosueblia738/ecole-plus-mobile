import '../network/api_client.dart';

class ClassesApiService {
  static Future<List<dynamic>> getAll({String? year}) async {
    final response = await ApiClient.instance.get(
      '/classes',
      params: {if (year != null) 'year': year},
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
}
