import 'package:flutter/material.dart';
import '../../../core/services/academic_year_api_service.dart';
import '../../../core/services/classes_api_service.dart';
import '../../../core/theme/app_colors.dart';

class _PassageRow {
  _PassageRow({
    required this.studentId,
    required this.name,
    required this.registrationNo,
  });

  final String studentId;
  final String name;
  final String registrationNo;
  bool selected = true;
  String decision = 'PASSAGE';
  String? targetClassId;
}

class StudentPassageScreen extends StatefulWidget {
  const StudentPassageScreen({super.key});

  @override
  State<StudentPassageScreen> createState() => _StudentPassageScreenState();
}

class _StudentPassageScreenState extends State<StudentPassageScreen> {
  List<Map<String, dynamic>> _years = [];
  String? _fromYearId;
  String? _toYearId;
  List<_PassageRow> _rows = [];
  List<Map<String, dynamic>> _targetClasses = [];
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  String? _resultMsg;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await AcademicYearApiService.getAll();
      final years =
          list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      Map<String, dynamic>? current;
      Map<String, dynamic>? next;
      for (final y in years) {
        if (y['isCurrent'] == true) current = y;
      }
      current ??= years.isNotEmpty ? years.first : null;
      for (final y in years) {
        if (y['id'] != current?['id'] && y['status'] != 'ARCHIVED') {
          next = y;
          break;
        }
      }
      if (!mounted) return;
      setState(() {
        _years = years;
        _fromYearId = current?['id'] as String?;
        _toYearId = next?['id'] as String?;
        _loading = false;
      });
      if (_fromYearId != null) await _loadStudents();
      if (_toYearId != null) await _loadTargetClasses();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Impossible de charger les années';
      });
    }
  }

  Future<void> _loadStudents() async {
    final fromId = _fromYearId;
    if (fromId == null) return;
    try {
      final enrollments = await AcademicYearApiService.getEnrollments(fromId);
      final rows = <_PassageRow>[];
      for (final raw in enrollments) {
        final e = Map<String, dynamic>.from(raw as Map);
        if (e['status'] != 'ENROLLED') continue;
        final student = Map<String, dynamic>.from(e['student'] as Map? ?? {});
        if (student['id'] == null) continue;
        rows.add(
          _PassageRow(
            studentId: student['id'] as String,
            name:
                '${student['lastName'] ?? ''} ${student['firstName'] ?? ''}'.trim(),
            registrationNo: student['registrationNo'] as String? ?? '',
          ),
        );
      }
      if (!mounted) return;
      setState(() => _rows = rows);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Impossible de charger les inscriptions');
    }
  }

  Future<void> _loadTargetClasses() async {
    Map<String, dynamic>? to;
    for (final y in _years) {
      if (y['id'] == _toYearId) to = y;
    }
    final label = to?['label'] as String?;
    if (label == null) {
      setState(() => _targetClasses = []);
      return;
    }
    try {
      final list = await ClassesApiService.getAll(year: label);
      if (!mounted) return;
      setState(() {
        _targetClasses =
            list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _targetClasses = []);
    }
  }

  Future<void> _submit() async {
    final fromId = _fromYearId;
    final toId = _toYearId;
    if (fromId == null || toId == null) {
      setState(() => _error = 'Sélectionnez les années');
      return;
    }
    final items = _rows
        .where((r) => r.selected && r.targetClassId != null)
        .map(
          (r) => {
            'studentId': r.studentId,
            'targetClassId': r.targetClassId,
            'decision': r.decision,
          },
        )
        .toList();
    if (items.isEmpty) {
      setState(() => _error = 'Sélectionnez des élèves avec une classe cible');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
      _resultMsg = null;
    });
    try {
      final res = await AcademicYearApiService.passage(
        fromYearId: fromId,
        toYearId: toId,
        items: items,
      );
      if (!mounted) return;
      setState(() {
        _resultMsg =
            '${res['successCount'] ?? 0} réussi(s), ${res['failureCount'] ?? 0} échec(s)';
      });
      await _loadStudents();
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Passage impossible');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Passage élèves'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null)
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                if (_resultMsg != null)
                  Text(_resultMsg!, style: const TextStyle(color: Colors.green)),
                DropdownButtonFormField<String>(
                  value: _fromYearId,
                  decoration: const InputDecoration(
                    labelText: 'Année source',
                    border: OutlineInputBorder(),
                  ),
                  items: _years
                      .map(
                        (y) => DropdownMenuItem(
                          value: y['id'] as String,
                          child: Text(y['label'] as String? ?? ''),
                        ),
                      )
                      .toList(),
                  onChanged: (v) async {
                    setState(() => _fromYearId = v);
                    await _loadStudents();
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _toYearId,
                  decoration: const InputDecoration(
                    labelText: 'Année cible',
                    border: OutlineInputBorder(),
                  ),
                  items: _years
                      .where((y) => y['status'] != 'ARCHIVED')
                      .map(
                        (y) => DropdownMenuItem(
                          value: y['id'] as String,
                          child: Text(y['label'] as String? ?? ''),
                        ),
                      )
                      .toList(),
                  onChanged: (v) async {
                    setState(() => _toYearId = v);
                    await _loadTargetClasses();
                  },
                ),
                if (_targetClasses.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Aucune classe sur l année cible — clonez d abord les classes.',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                const SizedBox(height: 12),
                ..._rows.map((r) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CheckboxListTile(
                            value: r.selected,
                            onChanged: (v) =>
                                setState(() => r.selected = v ?? false),
                            title: Text(r.name),
                            subtitle: Text(r.registrationNo),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: r.decision,
                                  decoration: const InputDecoration(
                                    labelText: 'Décision',
                                    isDense: true,
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'PASSAGE', child: Text('Passage')),
                                    DropdownMenuItem(
                                        value: 'REDOUBLEMENT',
                                        child: Text('Redoublement')),
                                    DropdownMenuItem(
                                        value: 'CONDITIONAL',
                                        child: Text('Conditionnel')),
                                  ],
                                  onChanged: (v) => setState(
                                      () => r.decision = v ?? 'PASSAGE'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: r.targetClassId,
                                  decoration: const InputDecoration(
                                    labelText: 'Classe cible',
                                    isDense: true,
                                  ),
                                  items: _targetClasses
                                      .map(
                                        (c) => DropdownMenuItem(
                                          value: c['id'] as String,
                                          child: Text(
                                            '${c['name']} (${c['level']})',
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => r.targetClassId = v),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(backgroundColor: primaryBlue),
                  child:
                      Text(_submitting ? 'Traitement…' : 'Valider le passage'),
                ),
              ],
            ),
    );
  }
}
