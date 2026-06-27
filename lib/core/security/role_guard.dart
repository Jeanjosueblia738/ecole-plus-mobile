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

  @override
  Widget build(BuildContext context) {
    if (UserSession.role != requiredRole) {
      return const Scaffold(
        body: Center(
          child: Text('Accès refusé'),
        ),
      );
    }

    return child;
  }
}
