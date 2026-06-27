import '../network/api_client.dart';
import 'auth_storage_service.dart';

class AuthApiService {
  // Login établissement — code école + email + mot de passe
  static Future<Map<String, dynamic>> login({
    required String tenantCode,
    required String email,
    required String password,
  }) async {
    final response = await ApiClient.instance.post('/auth/login', data: {
      'tenantCode': tenantCode.toUpperCase(),
      'email': email.toLowerCase(),
      'password': password,
    });

    final data = response.data as Map<String, dynamic>;

    // Sauvegarder le token et les infos
    await AuthStorageService.saveAuthData(
      token: data['access_token'],
      tenantCode: data['tenant']['code'],
      tenantName: data['tenant']['name'],
      role: data['user']['role'],
      email: data['user']['email'],
      userId: data['user']['id'],
    );

    return data;
  }

  // Login enseignant
  static Future<Map<String, dynamic>> loginTeacher({
    required String tenantCode,
    required String email,
    required String password,
  }) async {
    final response = await ApiClient.instance.post('/teachers/login', data: {
      'tenantCode': tenantCode.toUpperCase(),
      'email': email.toLowerCase(),
      'password': password,
    });

    final data = response.data as Map<String, dynamic>;

    await AuthStorageService.saveAuthData(
      token: data['access_token'],
      tenantCode: tenantCode,
      tenantName: tenantCode,
      role: 'TEACHER',
      email: data['teacher']['email'],
      userId: data['teacher']['id'],
    );

    return data;
  }

  static Future<void> logout() async => AuthStorageService.clearAll();
}
