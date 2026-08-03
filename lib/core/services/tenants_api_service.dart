import '../network/api_client.dart';
import '../models/tenant_brand.dart';

class TenantsApiService {
  /// Établissements du même groupe scolaire (staff uniquement)
  static Future<Map<String, dynamic>> getMyGroup() async {
    final response = await ApiClient.instance.get('/tenants/my-group');
    return response.data as Map<String, dynamic>;
  }

  static Future<TenantBrand> getMe() async {
    final response = await ApiClient.instance.get('/tenants/me');
    return TenantBrand.fromTenantMap(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  static Future<TenantBrand> updateBranding(Map<String, dynamic> data) async {
    final response = await ApiClient.instance.patch('/tenants/me', data: data);
    return TenantBrand.fromTenantMap(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}
