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
        body: Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Text(
                'Données locales uniquement — non synchronisées avec le serveur.',
                style: TextStyle(fontSize: 13),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: parents.isEmpty
                    ? const Center(
                        child: Text('Aucun parent disponible (local)'),
                      )
                    : ListView.builder(
                        itemCount: parents.length,
                        itemBuilder: (context, index) {
                          final parent = parents[index];

                          return Card(
                            child: ListTile(
                              title: Text(parent.fullName),
                              subtitle: Text(parent.phoneNumber),
                              trailing: Chip(
                                label: const Text('Local',
                                    style: TextStyle(fontSize: 11)),
                                backgroundColor: Colors.orange.shade50,
                                side: BorderSide(color: Colors.orange.shade200),
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
