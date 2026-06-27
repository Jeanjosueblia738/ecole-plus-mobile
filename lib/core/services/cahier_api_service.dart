import '../network/api_client.dart';

class CahierApiService {
  // Créer une entrée (enseignant)
  static Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final response = await ApiClient.instance.post('/cahier', data: data);
    return response.data as Map<String, dynamic>;
  }

  // Entrées par classe
  static Future<List<dynamic>> getByClass(String classId,
      {String? trimestre}) async {
    final response = await ApiClient.instance.get(
      '/cahier/classe/$classId',
      params: {if (trimestre != null) 'trimestre': trimestre},
    );
    return response.data as List<dynamic>;
  }

  // Émarger une entrée
  static Future<Map<String, dynamic>> emargement(String id) async {
    final response = await ApiClient.instance.patch('/cahier/$id/emargement');
    return response.data as Map<String, dynamic>;
  }

  // Stats (directeur)
  static Future<Map<String, dynamic>> getStats() async {
    final response = await ApiClient.instance.get('/cahier/stats');
    return response.data as Map<String, dynamic>;
  }

  // Supprimer
  static Future<void> delete(String id) async {
    await ApiClient.instance.delete('/cahier/$id');
  }
}
