import '../network/api_client.dart';

class SmsApiService {
  static Future<List<dynamic>> packs() async {
    final response = await ApiClient.instance.get('/sms/packs');
    final data = response.data;
    if (data is List) return data;
    return [];
  }

  static Future<Map<String, dynamic>> balance() async {
    final response = await ApiClient.instance.get('/sms/balance');
    return Map<String, dynamic>.from(response.data as Map);
  }

  static Future<Map<String, dynamic>> analytics() async {
    final response = await ApiClient.instance.get('/sms/analytics');
    return Map<String, dynamic>.from(response.data as Map);
  }

  static Future<List<dynamic>> purchases() async {
    final response = await ApiClient.instance.get('/sms/purchases');
    final data = response.data;
    if (data is List) return data;
    return [];
  }

  static Future<Map<String, dynamic>> purchase({
    required String packId,
    required String payerPhone,
  }) async {
    final response = await ApiClient.instance.post(
      '/sms/purchase',
      data: {'packId': packId, 'payerPhone': payerPhone},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }
}
