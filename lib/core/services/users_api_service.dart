import '../network/api_client.dart';

class UsersApiService {
  static Future<Map<String, dynamic>> getMyProfile() async {
    final response = await ApiClient.instance.get('/users/me');
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateMyProfile({
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    final response = await ApiClient.instance.patch('/users/me', data: {
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (phone != null) 'phone': phone,
    });
    return response.data as Map<String, dynamic>;
  }
}
