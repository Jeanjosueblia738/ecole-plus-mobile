import '../network/api_client.dart';
import '../../features/grades/data/grade_model.dart';

/// Catalogue matières école — `GET/POST/PUT/DELETE /subjects`.
class SubjectsApiService {
  static Future<List<Subject>> list({bool includeInactive = false}) async {
    final response = await ApiClient.instance.get(
      '/subjects',
      params: {
        if (includeInactive) 'includeInactive': true,
      },
    );
    final raw = response.data;
    final list = raw is List ? raw : (raw is Map ? (raw['data'] as List? ?? []) : []);
    final out = <Subject>[];
    for (final item in list) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final name = (map['name'] ?? '').toString().trim();
      if (name.isEmpty) continue;
      final coef = (map['coefficient'] as num?)?.toInt() ?? 1;
      final active = map['isActive'] != false;
      if (!includeInactive && !active) continue;
      out.add(Subject(
        id: map['id']?.toString(),
        name: name,
        coefficient: coef,
        isActive: active,
      ));
    }
    return out;
  }

  /// Liste API, sinon catalogue CI local de secours.
  static Future<List<Subject>> listOrDefaults() async {
    try {
      final rows = await list();
      if (rows.isNotEmpty) return rows;
    } catch (_) {}
    return List<Subject>.from(kDefaultSubjects);
  }

  static Future<Map<String, dynamic>> create({
    required String name,
    required int coefficient,
  }) async {
    final response = await ApiClient.instance.post(
      '/subjects',
      data: {'name': name.trim(), 'coefficient': coefficient},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  static Future<Map<String, dynamic>> update(
    String id, {
    String? name,
    int? coefficient,
    bool? isActive,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name.trim();
    if (coefficient != null) data['coefficient'] = coefficient;
    if (isActive != null) data['isActive'] = isActive;
    final response = await ApiClient.instance.put('/subjects/$id', data: data);
    return Map<String, dynamic>.from(response.data as Map);
  }

  static Future<void> remove(String id) async {
    await ApiClient.instance.delete('/subjects/$id');
  }
}
