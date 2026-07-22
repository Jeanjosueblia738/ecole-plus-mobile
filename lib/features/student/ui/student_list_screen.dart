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
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    await ref.read(studentProvider.notifier).load(
          search: _search.isEmpty ? null : _search,
        );
    final err = ref.read(studentProvider.notifier).error;
    if (mounted) {
      setState(() {
        _loading = false;
        _error = err;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final students = ref.watch(studentProvider);
    final classNames = ref.watch(classNamesProvider);
    final auth = ref.watch(authProvider);
    final canManageStudents = auth.isOwner || auth.isSecretary;

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
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      floatingActionButton: canManageStudents
          ? FloatingActionButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StudentFormScreen()),
                );
                _refresh();
              },
              backgroundColor: const Color(0xFF1E3A8A),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: Column(
        children: [
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
              onSubmitted: (_) => _refresh(),
            ),
          ),
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
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
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
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? const Center(child: Text('Aucun élève'))
                    : RefreshIndicator(
                        onRefresh: _refresh,
                        child: ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final s = filtered[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF1E3A8A)
                                    .withValues(alpha: 0.1),
                                child: Text(
                                  s.fullName.isNotEmpty
                                      ? s.fullName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                      color: Color(0xFF1E3A8A),
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(s.fullName),
                              subtitle: Text(
                                  '${s.className.isEmpty ? 'Sans classe' : s.className}'
                                  '${s.parentPhone.isNotEmpty ? ' · ${s.parentPhone}' : ''}'),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
