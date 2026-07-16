import '../network/api_client.dart';

class AttendanceApiService {
  static Future<Map<String, dynamic>> bulkCreate(
      Map<String, dynamic> data) async {
    final response =
        await ApiClient.instance.post('/attendance/bulk', data: data);
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> notifyAbsents(
      Map<String, dynamic> data) async {
    final response = await ApiClient.instance
        .post('/attendance/notify-absents', data: data);
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getByStudent(
    String studentId, {
    String? from,
    String? to,
  }) async {
    final response = await ApiClient.instance.get(
      '/attendance/student/$studentId',
      params: {
        if (from != null) 'from': from,
        if (to != null) 'to': to,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getByClass(
    String classId,
    String date, {
    String? subject,
  }) async {
    final response = await ApiClient.instance.get(
      '/attendance/class/$classId',
      params: {
        'date': date,
        if (subject != null) 'subject': subject,
      },
    );
    return response.data as List<dynamic>;
  }

  static Future<Map<String, dynamic>> justify(
    String id,
    String justification,
  ) async {
    final response = await ApiClient.instance.put(
      '/attendance/$id/justify',
      data: {'justification': justification},
    );
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getStats({String? classId}) async {
    final response = await ApiClient.instance.get(
      '/attendance/stats',
      params: {if (classId != null) 'classId': classId},
    );
    return response.data as Map<String, dynamic>;
  }
}
