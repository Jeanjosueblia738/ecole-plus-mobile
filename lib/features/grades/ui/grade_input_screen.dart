import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/student_provider.dart';
import '../../../core/services/grades_api_service.dart';
import '../../../core/sync/offline_outbox.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/dio_error_message.dart';
import '../data/grade_model.dart';

String _apiTrimestre(String raw) {
  final t = raw.trim().toUpperCase();
  if (t.startsWith('T')) return t;
  if (t.contains('1')) return 'T1';
  if (t.contains('2')) return 'T2';
  if (t.contains('3')) return 'T3';
  return 'T1';
}

String _apiEvalType(EvalType type) => switch (type) {
      EvalType.controle => 'CONTROLE',
      EvalType.devoir => 'DEVOIR',
      EvalType.examen => 'EXAMEN',
      EvalType.tp => 'TP',
    };

class GradeInputScreen extends ConsumerStatefulWidget {
  final String className;
  final String trimestre;
  final String? classId;
  final String? initialSubject;

  const GradeInputScreen({
    super.key,
    required this.className,
    required this.trimestre,
    this.classId,
    this.initialSubject,
  });

  @override
  ConsumerState<GradeInputScreen> createState() => _GradeInputScreenState();
}

class _GradeInputScreenState extends ConsumerState<GradeInputScreen> {
  Subject _selectedSubject = kSubjects.first;
  EvalType _evalType = EvalType.controle;
  final Map<String, TextEditingController> _controllers = {};
  bool _isSaving = false;
  bool _loadingStudents = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    if (widget.initialSubject != null && widget.initialSubject!.isNotEmpty) {
      final match = kSubjects
          .where((s) =>
              s.name.toLowerCase() == widget.initialSubject!.toLowerCase())
          .toList();
      if (match.isNotEmpty) {
        _selectedSubject = match.first;
      }
    }
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _loadingStudents = true;
      _loadError = null;
    });
    try {
      await ref.read(studentProvider.notifier).load(classId: widget.classId);
    } catch (_) {
      _loadError = 'Impossible de charger les élèves';
    }
    if (mounted) setState(() => _loadingStudents = false);
  }

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
    final students = widget.classId != null && widget.classId!.isNotEmpty
        ? ref.read(studentProvider.notifier).byClassId(widget.classId!)
        : ref.read(studentProvider.notifier).byClass(widget.className);

    final gradesPayload = <Map<String, dynamic>>[];
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

      gradesPayload.add({
        'studentId': student.id,
        'subject': _selectedSubject.name,
        'value': value,
        'trimestre': _apiTrimestre(widget.trimestre),
        'evalType': _apiEvalType(_evalType),
        'coefficient': _selectedSubject.coefficient,
      });
    }

    if (gradesPayload.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Aucune note saisie'),
      ));
      return;
    }

    final classId = widget.classId ??
        students.map((s) => s.classId).firstWhere(
              (id) => id != null && id.isNotEmpty,
              orElse: () => null,
            );
    if (classId == null || classId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Classe introuvable — rouvrez depuis une classe API'),
        backgroundColor: dangerRed,
      ));
      return;
    }

    setState(() => _isSaving = true);
    final payload = {
      'classId': classId,
      'grades': gradesPayload,
    };
    try {
      await GradesApiService.bulkCreate(payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            '${gradesPayload.length} note${gradesPayload.length > 1 ? 's' : ''} enregistrée${gradesPayload.length > 1 ? 's' : ''}'),
        backgroundColor: successGreen,
      ));
      Navigator.pop(context);
    } catch (e) {
      if (isOfflineEnqueueableError(e)) {
        await OfflineOutbox.enqueue(type: 'grades.bulk', payload: payload);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Hors ligne — notes mises en file, sync au retour réseau'),
          backgroundColor: Colors.orange,
        ));
      } else {
        if (!mounted) return;
        final msg = e is DioException
            ? dioErrorMessage(e, fallback: 'Erreur lors de l\'enregistrement')
            : e.toString();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: dangerRed,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final students = widget.classId != null && widget.classId!.isNotEmpty
        ? ref.watch(studentProvider.notifier).byClassId(widget.classId!)
        : ref.watch(studentProvider.notifier).byClass(widget.className);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(widget.className.isEmpty
            ? 'Saisie des notes'
            : 'Notes — ${widget.className}'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: primaryBlue.withValues(alpha: 0.05),
            child: Column(
              children: [
                DropdownButtonFormField<Subject>(
                  initialValue: _selectedSubject,
                  decoration: const InputDecoration(
                    labelText: 'Matière',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: kSubjects
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text('${s.name} (coef ${s.coefficient})'),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedSubject = v);
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<EvalType>(
                  initialValue: _evalType,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: EvalType.values
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(e.label),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _evalType = v);
                  },
                ),
              ],
            ),
          ),
          if (_loadError != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(_loadError!, style: const TextStyle(color: dangerRed)),
            ),
          Expanded(
            child: _loadingStudents
                ? const Center(child: CircularProgressIndicator())
                : students.isEmpty
                    ? const Center(child: Text('Aucun élève dans cette classe'))
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 100),
                        itemCount: students.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, indent: 16),
                        itemBuilder: (context, index) {
                          final student = students[index];
                          final initial = student.fullName.isNotEmpty
                              ? student.fullName[0].toUpperCase()
                              : '?';
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
                                          initial,
                                          style: const TextStyle(
                                              color: primaryBlue,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(student.fullName,
                                            style:
                                                const TextStyle(fontSize: 14)),
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
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 8),
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving || _loadingStudents ? null : _save,
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
