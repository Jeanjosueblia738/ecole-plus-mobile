import '../network/api_client.dart';

class ParentApiService {
  /// Liste tous les enfants liés au parent.
  static Future<List<Map<String, dynamic>>> getMyChildren() async {
    final response = await ApiClient.instance.get('/students/my-children');
    final data = response.data;
    if (data is List) {
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  /// Un enfant (optionnellement choisi via studentId).
  static Future<Map<String, dynamic>> getMyChild({String? studentId}) async {
    final response = await ApiClient.instance.get(
      '/students/my-child',
      params: {if (studentId != null) 'studentId': studentId},
    );
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getChildGrades(
    String studentId, {
    String? trimestre,
  }) async {
    final response = await ApiClient.instance.get(
      '/grades/student/$studentId',
      params: {if (trimestre != null) 'trimestre': trimestre},
    );
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getChildAttendance(
      String studentId) async {
    final response = await ApiClient.instance.get(
      '/attendance/student/$studentId',
    );
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getChildFinance(String studentId) async {
    final response = await ApiClient.instance.get(
      '/finance/student/$studentId',
    );
    return response.data as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getMyAlerts() async {
    final response = await ApiClient.instance.get('/finance/alerts/me');
    return response.data as List<dynamic>;
  }

  static Future<Map<String, dynamic>> getChildTimetable({
    String? year,
    String? studentId,
  }) async {
    final response = await ApiClient.instance.get(
      '/timetable/my-child',
      params: {
        if (year != null) 'year': year,
        if (studentId != null) 'studentId': studentId,
      },
    );
    return response.data as Map<String, dynamic>;
  }
}
