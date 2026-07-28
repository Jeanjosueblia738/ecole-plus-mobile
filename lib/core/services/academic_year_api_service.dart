import '../network/api_client.dart';

class AcademicYearApiService {
  static Future<List<dynamic>> getAll() async {
    final response = await ApiClient.instance.get('/academic-years');
    return response.data as List<dynamic>;
  }

  static Future<Map<String, dynamic>> getCurrent() async {
    final response = await ApiClient.instance.get('/academic-years/current');
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> create({
    required String label,
    String? startDate,
    String? endDate,
  }) async {
    final response = await ApiClient.instance.post(
      '/academic-years',
      data: {
        'label': label,
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> activate(String id) async {
    final response =
        await ApiClient.instance.patch('/academic-years/$id/activate');
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> archive(String id) async {
    final response =
        await ApiClient.instance.patch('/academic-years/$id/archive');
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> cloneClasses({
    required String targetYearId,
    required String sourceYearId,
  }) async {
    final response = await ApiClient.instance.post(
      '/academic-years/$targetYearId/clone-classes',
      data: {'sourceYearId': sourceYearId},
    );
    return response.data as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getEnrollments(String yearId) async {
    final response =
        await ApiClient.instance.get('/academic-years/$yearId/enrollments');
    return response.data as List<dynamic>;
  }

  static Future<Map<String, dynamic>> passage({
    required String fromYearId,
    required String toYearId,
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await ApiClient.instance.post(
      '/academic-years/passage',
      data: {
        'fromYearId': fromYearId,
        'toYearId': toYearId,
        'items': items,
      },
    );
    return response.data as Map<String, dynamic>;
  }
}
