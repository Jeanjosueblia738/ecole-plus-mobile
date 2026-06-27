import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/grade_provider.dart';
import '../../../core/providers/student_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../data/grade_model.dart';

class GradeInputScreen extends ConsumerStatefulWidget {
  final String className;
  final String trimestre;

  const GradeInputScreen({
    super.key,
    required this.className,
    required this.trimestre,
  });

  @override
  ConsumerState<GradeInputScreen> createState() => _GradeInputScreenState();
}

class _GradeInputScreenState extends ConsumerState<GradeInputScreen> {
  Subject _selectedSubject = kSubjects.first;
  EvalType _evalType = EvalType.controle;
  // studentId → controller de saisie
  final Map<String, TextEditingController> _controllers = {};
  bool _isSaving = false;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _ctrl(String studentId) {
    return _controllers.putIfAbsent(studentId, () => TextEditingController());
  }

  Future<void> _save() async {
    final students =
        ref.read(studentProvider.notifier).byClass(widget.className);

    final date = DateFormat('dd/MM/yyyy').format(DateTime.now());
    final newGrades = <Grade>[];

    for (final student in students) {
      final raw = _controllers[student.id]?.text.trim();
      if (raw == null || raw.isEmpty) continue;

      final value = double.tryParse(raw.replaceAll(',', '.'));
      if (value == null || value < 0 || value > 20) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Note invalide pour ${student.fullName} — saisir entre 0 et 20'),
          backgroundColor: dangerRed,
        ));
        return;
      }

      newGrades.add(Grade(
        id: '${student.id}_${_selectedSubject.name}_${DateTime.now().millisecondsSinceEpoch}',
        studentId: student.id,
        studentName: student.fullName,
        className: widget.className,
        subject: _selectedSubject.name,
        coefficient: _selectedSubject.coefficient,
        value: value,
        evalType: _evalType,
        trimestre: widget.trimestre,
        date: date,
      ));
    }

    if (newGrades.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Aucune note saisie'),
      ));
      return;
    }

    setState(() => _isSaving = true);
    await ref.read(gradeProvider.notifier).addGrades(newGrades);
    setState(() => _isSaving = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          '${newGrades.length} note${newGrades.length > 1 ? 's' : ''} enregistrée${newGrades.length > 1 ? 's' : ''}'),
      backgroundColor: successGreen,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final students =
        ref.watch(studentProvider.notifier).byClass(widget.className);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Saisie des notes'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Sélecteurs matière + type ──────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            color: primaryBlue.withValues(alpha: 0.05),
            child: Column(
              children: [
                // Matière
                DropdownButtonFormField<Subject>(
                  initialValue: _selectedSubject,
                  decoration: InputDecoration(
                    labelText: 'Matière',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                  ),
                  items: kSubjects
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text('${s.name}  (coef. ${s.coefficient})'),
                          ))
                      .toList(),
                  onChanged: (s) {
                    if (s != null) setState(() => _selectedSubject = s);
                  },
                ),
                const SizedBox(height: 12),
                // Type d'évaluation
                Row(
                  children: EvalType.values.map((type) {
                    final selected = _evalType == type;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(type.label),
                          selected: selected,
                          selectedColor: primaryBlue.withValues(alpha: 0.2),
                          labelStyle: TextStyle(
                            color: selected ? primaryBlue : textGrey,
                            fontWeight:
                                selected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13,
                          ),
                          onSelected: (_) => setState(() => _evalType = type),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // En-tête colonnes
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                    child: Text('Élève',
                        style: TextStyle(
                            color: textGrey,
                            fontWeight: FontWeight.bold,
                            fontSize: 13))),
                SizedBox(
                  width: 100,
                  child: Text('/20',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: textGrey,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Liste élèves + champs notes ────────────────────────────
          Expanded(
            child: students.isEmpty
                ? Center(
                    child: Text(
                      'Aucun élève dans ${widget.className}',
                      style: const TextStyle(color: textGrey),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: students.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 16),
                    itemBuilder: (context, index) {
                      final student = students[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor:
                                        primaryBlue.withValues(alpha: 0.12),
                                    child: Text(
                                      student.fullName[0].toUpperCase(),
                                      style: const TextStyle(
                                          color: primaryBlue,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(student.fullName,
                                        style: const TextStyle(fontSize: 14)),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 100,
                              child: TextField(
                                controller: _ctrl(student.id),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  hintText: '—',
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 8),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      // ── Bouton enregistrer flottant ────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _save,
        backgroundColor: primaryBlue,
        icon: _isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.save, color: Colors.white),
        label: Text(
          _isSaving ? 'Enregistrement...' : 'Enregistrer',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
