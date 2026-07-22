import 'package:ecole_plus_mobile/core/security/user_role.dart';

// UserRole est défini dans core/security/user_role.dart — ne pas le redéfinir ici

class UserSession {
  static UserRole? _currentRole;

  // 🔹 Initialisation au lancement
  static Future<void> init() async {
    _currentRole = null;
  }

  // 🔹 Getter principal
  static UserRole? get role => _currentRole;

  // 🔹 Alias pour compatibilité
  static UserRole? get currentUserRole => _currentRole;

  // 🔹 Définir le rôle (usage interne ou tests)
  static void setRole(UserRole role) {
    _currentRole = role;
  }

  // 🔹 Vérifications rapides
  static bool get isAdmin => _currentRole == UserRole.admin;
  static bool get isOwner =>
      _currentRole == UserRole.admin || _currentRole == UserRole.founder;
  static bool get isDirection =>
      _currentRole == UserRole.admin ||
      _currentRole == UserRole.founder ||
      _currentRole == UserRole.director;
  static bool get isTeacher => _currentRole == UserRole.teacher;
  static bool get isParent => _currentRole == UserRole.parent;
  static bool get isLoggedIn => _currentRole != null;

  // 🔹 Logout
  static Future<void> clear() async {
    _currentRole = null;
  }
}
