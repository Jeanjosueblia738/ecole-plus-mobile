import 'package:flutter/material.dart';
import '../data/student.dart';
import '../data/student_store.dart';

class StudentFormScreen extends StatefulWidget {
  final Student? student;

  const StudentFormScreen({super.key, this.student});

  @override
  State<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends State<StudentFormScreen> {
  final nameCtrl = TextEditingController();
  final classCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.student != null) {
      nameCtrl.text = widget.student!.fullName;
      classCtrl.text = widget.student!.className;
      phoneCtrl.text = widget.student!.parentPhone;
    }
  }

  Future<void> save() async {
    if (nameCtrl.text.isEmpty ||
        classCtrl.text.isEmpty ||
        phoneCtrl.text.isEmpty) {
      return;
    }

    if (widget.student == null) {
      await StudentStore.add(
        Student(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          fullName: nameCtrl.text,
          className: classCtrl.text,
          parentPhone: phoneCtrl.text,
        ),
      );
    } else {
      widget.student!
        ..fullName = nameCtrl.text
        ..className = classCtrl.text
        ..parentPhone = phoneCtrl.text;

      await StudentStore.update(widget.student!);
    }

    if (!mounted) return;
    Navigator.pop(context);
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
        child: Column(
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nom complet'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: classCtrl,
              decoration: const InputDecoration(labelText: 'Classe'),
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
                onPressed: save,
                child: const Text('Enregistrer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
