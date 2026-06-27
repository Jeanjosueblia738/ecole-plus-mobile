import 'parent.dart';

class ParentStore {
  static final List<Parent> _parents = [];

  // 🔹 Récupérer tous les parents
  static List<Parent> getAll() {
    return List.unmodifiable(_parents);
  }

  // 🔹 Ajouter un parent
  static Future<void> add(Parent parent) async {
    _parents.add(parent);
  }

  // 🔹 Mettre à jour un parent
  static Future<void> update(Parent parent) async {
    final index = _parents.indexWhere((p) => p.id == parent.id);

    if (index != -1) {
      _parents[index] = parent;
    }
  }

  // 🔹 Supprimer un parent
  static Future<void> delete(String id) async {
    _parents.removeWhere((p) => p.id == id);
  }

  // 🔹 Récupérer un parent par ID (optionnel mais propre)
  static Parent? getById(String id) {
    try {
      return _parents.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }
}