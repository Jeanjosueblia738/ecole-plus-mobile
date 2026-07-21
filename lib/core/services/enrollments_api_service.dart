import '../network/api_client.dart';

class EnrollmentsApiService {
  /// Pré-inscription publique (sans JWT)
  static Future<Map<String, dynamic>> submitPublic(
      Map<String, dynamic> data) async {
    final response =
        await ApiClient.instance.post('/enrollments', data: data);
    return response.data as Map<String, dynamic>;
  }

  /// Liste des demandes — staff
  static Future<List<dynamic>> list({String? status}) async {
    final response = await ApiClient.instance.get(
      '/enrollments',
      params: {if (status != null) 'status': status},
    );
    return response.data as List<dynamic>;
  }

  /// Approuver / refuser une demande
  static Future<Map<String, dynamic>> review(
    String id, {
    required String status,
    String? classId,
    String? registrationNo,
    String? rejectionReason,
  }) async {
    final response = await ApiClient.instance.patch('/enrollments/$id', data: {
      'status': status,
      if (classId != null) 'classId': classId,
      if (registrationNo != null) 'registrationNo': registrationNo,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
    });
    return response.data as Map<String, dynamic>;
  }
}
