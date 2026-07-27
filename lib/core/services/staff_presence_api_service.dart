import '../network/api_client.dart';
import 'package:dio/dio.dart';

class StaffPresenceApiService {
  static Future<Map<String, dynamic>> campusQrScan({
    required String payload,
    required DateTime clientTime,
  }) async {
    try {
      final response = await ApiClient.instance.post(
        '/staff-presence/qr-scan',
        data: {
          'payload': payload,
          'clientTime': clientTime.toUtc().toIso8601String(),
        },
      );
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response!.data['message'] ?? e.message)
          : e.message;
      throw Exception(
        msg is List ? msg.join(' · ') : (msg?.toString() ?? 'Scan impossible'),
      );
    }
  }

  static Future<List<dynamic>> today({String? date}) async {
    final response = await ApiClient.instance.get(
      '/staff-presence/today',
      params: {if (date != null) 'date': date},
    );
    return response.data as List<dynamic>;
  }

  static Future<Map<String, dynamic>> campusQr() async {
    final response = await ApiClient.instance.get('/staff-presence/campus-qr');
    return Map<String, dynamic>.from(response.data as Map);
  }
}

class PresenceAlertsApiService {
  static Future<Map<String, dynamic>> todayAlerts() async {
    final response = await ApiClient.instance.get('/payroll/alerts/today');
    return Map<String, dynamic>.from(response.data as Map);
  }

  static Future<Map<String, dynamic>> assignSubstitute({
    required String occurrenceId,
    String? substituteTeacherId,
  }) async {
    final response = await ApiClient.instance.patch(
      '/payroll/occurrences/$occurrenceId/substitute',
      data: {'substituteTeacherId': substituteTeacherId},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  static Future<Map<String, dynamic>> reportUncovered({
    required String occurrenceId,
    String? note,
  }) async {
    final response = await ApiClient.instance.post(
      '/payroll/occurrences/$occurrenceId/report-uncovered',
      data: {if (note != null) 'note': note},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  static Future<List<dynamic>> listTeachers() async {
    final response = await ApiClient.instance.get('/teachers');
    final data = response.data;
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'] as List;
    return [];
  }
}
