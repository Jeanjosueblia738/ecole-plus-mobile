import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/profile_provider.dart';
import '../core/security/user_role.dart';
import '../features/auth/ui/login_screen.dart';
import '../features/admin/ui/admin_dashboard.dart';
import '../features/censor/ui/censor_dashboard.dart';
import '../features/surveillant/ui/surveillant_dashboard.dart';
import '../features/accountant/ui/accountant_dashboard.dart';
import '../features/secretary/ui/secretary_dashboard.dart';
import '../features/teacher/ui/teacher_dashboard.dart';
import '../features/parent/ui/parent_dashboard.dart';
import '../features/student/ui/student_dashboard.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState.role != null) {
      ref.read(profileProvider.notifier).loadForRole(
            authState.role!,
            userId: authState.userId,
            fullName: authState.fullName,
            email: authState.email,
            etablissement: authState.tenantName,
          );
    }

    return switch (authState.role) {
      UserRole.admin => const AdminDashboard(),
      UserRole.censor => const CensorDashboard(),
      UserRole.surveillant => const SurveillantDashboard(),
      UserRole.secretary => const SecretaryDashboard(),
      UserRole.accountant => const AccountantDashboard(),
      UserRole.teacher => const TeacherDashboard(),
      UserRole.parent => const ParentDashboard(),
      UserRole.student => const StudentDashboard(),
      null => const LoginScreen(),
    };
  }
}
