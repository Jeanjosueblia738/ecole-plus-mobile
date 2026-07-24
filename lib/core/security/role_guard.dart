import 'package:flutter/material.dart';
import 'package:ecole_plus_mobile/core/session/user_session.dart';
import 'package:ecole_plus_mobile/core/security/user_role.dart';

class RoleGuard extends StatelessWidget {
  final UserRole requiredRole;
  final Widget child;

  const RoleGuard({
    super.key,
    required this.requiredRole,
    required this.child,
  });

  bool _isAllowed(UserRole? current) {
    if (current == null) return false;
    if (current == requiredRole) return true;
    // ADMIN gate = direction (FOUNDER / DIRECTOR) — aligné sur isDirection.
    if (requiredRole == UserRole.admin && current.isDirection) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAllowed(UserSession.role)) {
      return const Scaffold(
        body: Center(
          child: Text('Accès refusé'),
        ),
      );
    }

    return child;
  }
}
