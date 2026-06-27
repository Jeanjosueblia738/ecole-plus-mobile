import 'package:flutter/material.dart';
import '../../../core/security/user_role.dart';
import '../../../core/security/role_guard.dart';
import '../../parent/data/parent_store.dart';

class ParentListScreen extends StatelessWidget {
  const ParentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final parents = ParentStore.getAll();

    return RoleGuard(
      requiredRole: UserRole.admin,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Liste des parents'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: parents.isEmpty
              ? const Center(
                  child: Text('Aucun parent disponible'),
                )
              : ListView.builder(
                  itemCount: parents.length,
                  itemBuilder: (context, index) {
                    final parent = parents[index];

                    return Card(
                      child: ListTile(
                        title: Text(parent.fullName),      // ✅ FIX
                        subtitle: Text(parent.phoneNumber), // ✅ FIX
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}