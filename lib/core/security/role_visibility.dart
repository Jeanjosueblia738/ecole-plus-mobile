import 'package:ecole_plus_mobile/core/security/user_role.dart';

class RoleVisibility {
  static bool canSeeParentFeatures(UserRole role) {
    return role == UserRole.parent;
  }

  static bool canSeeTeacherFeatures(UserRole role) {
    return role == UserRole.teacher;
  }

  static bool canSeeAdminFeatures(UserRole role) {
    return role.isDirection;
  }
}
