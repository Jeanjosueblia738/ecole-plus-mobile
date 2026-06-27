import '../network/api_client.dart';

class GradesApiService {
  static Future<Map<String, dynamic>> getByStudent(
    String studentId, {
    String? trimestre,
  }) async {
    final response = await ApiClient.instance.get(
      '/grades/student/$studentId',
      params: {if (trimestre != null) 'trimestre': trimestre},
    );
    return response.data as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getByClass(
    String classId,
    String trimestre, {
    String? subject,
  }) async {
    final response = await ApiClient.instance.get(
      '/grades/class/$classId',
      params: {
        'trimestre': trimestre,
        if (subject != null) 'subject': subject,
      },
    );
    return response.data as List<dynamic>;
  }

  static Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final response = await ApiClient.instance.post('/grades', data: data);
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> bulkCreate(
      Map<String, dynamic> data) async {
    final response = await ApiClient.instance.post('/grades/bulk', data: data);
    return response.data as Map<String, dynamic>;
  }
}
