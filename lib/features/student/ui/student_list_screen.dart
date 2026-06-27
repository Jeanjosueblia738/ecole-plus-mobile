import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/student_provider.dart';
import 'student_form_screen.dart';

class StudentListScreen extends ConsumerStatefulWidget {
  const StudentListScreen({super.key});

  @override
  ConsumerState<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends ConsumerState<StudentListScreen> {
  String _search = '';
  String _selectedClass = 'Toutes';

  @override
  Widget build(BuildContext context) {
    // Riverpod : lecture réactive — la liste se met à jour automatiquement
    final students = ref.watch(studentProvider);
    final classNames = ref.watch(classNamesProvider);
    final isAdmin = ref.watch(authProvider).isAdmin;

    // Sécurité : si la classe sélectionnée n'existe plus, on reset
    if (!classNames.contains(_selectedClass)) {
      _selectedClass = 'Toutes';
    }

    final filtered = students.where((s) {
      final matchSearch =
          s.fullName.toLowerCase().contains(_search.toLowerCase());
      final matchClass =
          _selectedClass == 'Toutes' || s.className == _selectedClass;
      return matchSearch && matchClass;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des élèves'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StudentFormScreen()),
              ),
              backgroundColor: const Color(0xFF1E3A8A),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: Column(
        children: [
          // 🔍 Recherche
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Rechercher un élève...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),

          // 🎯 Filtre classe — données dynamiques depuis classNamesProvider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonFormField<String>(
              initialValue: _selectedClass,
              items: classNames
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedClass = v ?? 'Toutes'),
              decoration: const InputDecoration(
                labelText: 'Filtrer par classe',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),

          // Compteur
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${filtered.length} élève${filtered.length > 1 ? 's' : ''}',
                  style:
                      const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                ),
              ],
            ),
          ),

          // 📋 Liste réactive
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      'Aucun élève trouvé',
                      style: TextStyle(color: Color(0xFF6B7280)),
                    ),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final student = filtered[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF1E3A8A),
                          child: Text(
                            student.fullName[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(student.fullName),
                        subtitle: Text(student.className),
                        trailing:
                            isAdmin ? const Icon(Icons.edit, size: 18) : null,
                        onTap: isAdmin
                            ? () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        StudentFormScreen(student: student),
                                  ),
                                )
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
