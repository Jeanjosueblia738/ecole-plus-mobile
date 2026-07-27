import '../network/api_client.dart';

class AbsenceAuthApiService {
  static Future<List<dynamic>> list({String? status, String? kind}) async {
    final response = await ApiClient.instance.get(
      '/absence-auth',
      params: {
        if (status != null) 'status': status,
        if (kind != null) 'kind': kind,
      },
    );
    return response.data as List<dynamic>;
  }

  static Future<Map<String, dynamic>> createStudent({
    String? studentId,
    required String startDate,
    required String endDate,
    required String reason,
  }) async {
    final response = await ApiClient.instance.post(
      '/absence-auth/student',
      data: {
        if (studentId != null) 'studentId': studentId,
        'startDate': startDate,
        'endDate': endDate,
        'reason': reason,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> createStaff({
    required String startDate,
    required String endDate,
    required String reason,
  }) async {
    final response = await ApiClient.instance.post(
      '/absence-auth/staff',
      data: {
        'startDate': startDate,
        'endDate': endDate,
        'reason': reason,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> approve(String id,
      {String? decisionNote}) async {
    final response = await ApiClient.instance.patch(
      '/absence-auth/$id/approve',
      data: {if (decisionNote != null) 'decisionNote': decisionNote},
    );
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> reject(String id,
      {String? decisionNote}) async {
    final response = await ApiClient.instance.patch(
      '/absence-auth/$id/reject',
      data: {if (decisionNote != null) 'decisionNote': decisionNote},
    );
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> cancel(String id) async {
    final response =
        await ApiClient.instance.patch('/absence-auth/$id/cancel');
    return response.data as Map<String, dynamic>;
  }
}
