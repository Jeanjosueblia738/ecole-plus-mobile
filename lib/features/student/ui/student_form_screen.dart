import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/students_api_service.dart';
import '../../../core/services/classes_api_service.dart';
import '../data/student.dart';

class StudentFormScreen extends ConsumerStatefulWidget {
  final Student? student;

  const StudentFormScreen({super.key, this.student});

  @override
  ConsumerState<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends ConsumerState<StudentFormScreen> {
  final firstCtrl = TextEditingController();
  final lastCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final regCtrl = TextEditingController();
  List<dynamic> _classes = [];
  String? _classId;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.student != null) {
      final parts = widget.student!.fullName.split(' ');
      firstCtrl.text = parts.isNotEmpty ? parts.first : '';
      lastCtrl.text = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      phoneCtrl.text = widget.student!.parentPhone;
      _classId = widget.student!.classId;
    }
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    try {
      final data = await ClassesApiService.getAll();
      if (mounted) setState(() => _classes = data);
    } catch (_) {}
  }

  @override
  void dispose() {
    firstCtrl.dispose();
    lastCtrl.dispose();
    phoneCtrl.dispose();
    regCtrl.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (firstCtrl.text.isEmpty || lastCtrl.text.isEmpty) {
      setState(() => _error = 'Prénom et nom requis');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (widget.student == null) {
        await StudentsApiService.create({
          'firstName': firstCtrl.text.trim(),
          'lastName': lastCtrl.text.trim(),
          'registrationNo': regCtrl.text.trim().isEmpty
              ? 'ELV-${DateTime.now().millisecondsSinceEpoch % 100000}'
              : regCtrl.text.trim(),
          'gender': 'MALE',
          'statut': _classId != null ? 'AFFECTE' : 'NON_AFFECTE',
          if (_classId != null) 'classId': _classId,
          'parentPhone': phoneCtrl.text.trim().isEmpty
              ? null
              : phoneCtrl.text.trim(),
        });
      } else {
        await StudentsApiService.update(widget.student!.id, {
          'firstName': firstCtrl.text.trim(),
          'lastName': lastCtrl.text.trim(),
          if (_classId != null) 'classId': _classId,
          'parentPhone': phoneCtrl.text.trim().isEmpty
              ? null
              : phoneCtrl.text.trim(),
        });
      }
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      setState(() => _error = 'Erreur: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.student == null ? 'Ajouter élève' : 'Modifier élève',
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            TextField(
              controller: firstCtrl,
              decoration: const InputDecoration(labelText: 'Prénom *'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: lastCtrl,
              decoration: const InputDecoration(labelText: 'Nom *'),
            ),
            const SizedBox(height: 16),
            if (widget.student == null)
              TextField(
                controller: regCtrl,
                decoration: const InputDecoration(
                    labelText: 'Matricule (auto si vide)'),
              ),
            if (widget.student == null) const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _classId,
              decoration: const InputDecoration(labelText: 'Classe'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Non affecté')),
                ..._classes.map((c) => DropdownMenuItem(
                      value: c['id']?.toString(),
                      child: Text('${c['name'] ?? ''}'),
                    )),
              ],
              onChanged: (v) => setState(() => _classId = v),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneCtrl,
              decoration:
                  const InputDecoration(labelText: 'Téléphone du parent'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Enregistrer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
