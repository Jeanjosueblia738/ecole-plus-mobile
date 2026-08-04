import '../network/api_client.dart';

class CampusApiService {
  static Future<Map<String, dynamic>> overview() async {
    final response = await ApiClient.instance.get('/campus/overview');
    return Map<String, dynamic>.from(response.data as Map);
  }

  static Future<List<dynamic>> listBooks() async {
    final response = await ApiClient.instance.get('/campus/library');
    final data = response.data;
    if (data is List) return data;
    return [];
  }

  static Future<Map<String, dynamic>> createBook(Map<String, dynamic> data) async {
    final response =
        await ApiClient.instance.post('/campus/library', data: data);
    return Map<String, dynamic>.from(response.data as Map);
  }

  static Future<List<dynamic>> listRoutes() async {
    final response = await ApiClient.instance.get('/campus/transport');
    final data = response.data;
    if (data is List) return data;
    return [];
  }

  static Future<Map<String, dynamic>> createRoute(Map<String, dynamic> data) async {
    final response =
        await ApiClient.instance.post('/campus/transport', data: data);
    return Map<String, dynamic>.from(response.data as Map);
  }

  static Future<List<dynamic>> listPlans() async {
    final response = await ApiClient.instance.get('/campus/canteen');
    final data = response.data;
    if (data is List) return data;
    return [];
  }

  static Future<Map<String, dynamic>> createPlan(Map<String, dynamic> data) async {
    final response =
        await ApiClient.instance.post('/campus/canteen', data: data);
    return Map<String, dynamic>.from(response.data as Map);
  }
}
