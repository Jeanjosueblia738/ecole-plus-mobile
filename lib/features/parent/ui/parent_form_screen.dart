import 'package:flutter/material.dart';
import '../data/parent.dart';
import '../data/parent_store.dart';
import '../../student/data/student_store.dart';

class ParentFormScreen extends StatefulWidget {
  final Parent? parent;
  const ParentFormScreen({super.key, this.parent});

  @override
  State<ParentFormScreen> createState() => _ParentFormScreenState();
}

class _ParentFormScreenState extends State<ParentFormScreen> {
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final selectedStudents = <String>{};

  @override
  void initState() {
    super.initState();
    if (widget.parent != null) {
      nameCtrl.text = widget.parent!.fullName;
      phoneCtrl.text = widget.parent!.phoneNumber;
      selectedStudents.addAll(widget.parent!.studentIds);
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    // ✅ Validation
    if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
      // context utilisé de manière synchrone ici — pas de gap async → pas de warning
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    if (widget.parent == null) {
      await ParentStore.add(
        Parent(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          fullName: nameCtrl.text.trim(),
          phoneNumber: phoneCtrl.text.trim(),
          studentIds: selectedStudents.toList(),
        ),
      );
    } else {
      widget.parent!
        ..fullName = nameCtrl.text.trim()
        ..phoneNumber = phoneCtrl.text.trim()
        ..studentIds = selectedStudents.toList();
      await ParentStore.update(widget.parent!);
    }

    // ✅ Vérification mounted APRÈS l'await avant tout usage de context
    if (!mounted) return;

    final message =
        widget.parent == null ? 'Parent ajouté' : 'Parent mis à jour';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final students = StudentStore.getStudents();

    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.parent == null ? 'Ajouter parent' : 'Modifier parent'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nom complet'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Téléphone'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Enfants associés',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ...students.map(
              (s) => CheckboxListTile(
                title: Text(s.fullName),
                value: selectedStudents.contains(s.id),
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      selectedStudents.add(s.id);
                    } else {
                      selectedStudents.remove(s.id);
                    }
                  });
                },
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _save,
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}
