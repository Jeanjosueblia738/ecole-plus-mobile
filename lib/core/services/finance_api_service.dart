import '../network/api_client.dart';

class FinanceApiService {
  static Future<Map<String, dynamic>> getStudentFinance(
      String studentId) async {
    final response =
        await ApiClient.instance.get('/finance/student/$studentId');
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> recordPayment(
      Map<String, dynamic> data) async {
    final response =
        await ApiClient.instance.post('/finance/payments', data: data);
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getStats({String? year}) async {
    final response = await ApiClient.instance.get(
      '/finance/stats',
      params: {if (year != null) 'year': year},
    );
    return response.data as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getFees({String? year}) async {
    final response = await ApiClient.instance.get(
      '/finance/fees',
      params: {if (year != null) 'year': year},
    );
    return response.data as List<dynamic>;
  }

  static Future<Map<String, dynamic>> createFee(Map<String, dynamic> data) async {
    final response = await ApiClient.instance.post('/finance/fees', data: data);
    return response.data as Map<String, dynamic>;
  }
}
