import '../network/api_client.dart';

class TenantsApiService {
  /// Établissements du même groupe scolaire (staff uniquement)
  static Future<Map<String, dynamic>> getMyGroup() async {
    final response = await ApiClient.instance.get('/tenants/my-group');
    return response.data as Map<String, dynamic>;
  }
}
