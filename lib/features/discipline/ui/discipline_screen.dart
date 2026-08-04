import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/parent_provider.dart';
import '../../../core/security/user_role.dart';
import '../../../core/services/classes_api_service.dart';
import '../../../core/services/discipline_api_service.dart';
import '../../../core/services/students_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/school_year.dart';

class DisciplineScreen extends ConsumerStatefulWidget {
  const DisciplineScreen({super.key, this.studentId});

  final String? studentId;

  @override
  ConsumerState<DisciplineScreen> createState() => _DisciplineScreenState();
}

class _DisciplineScreenState extends ConsumerState<DisciplineScreen> {
  static const _canWriteRoles = {
    UserRole.admin,
    UserRole.founder,
    UserRole.director,
    UserRole.censor,
    UserRole.surveillant,
  };
  static const _canDeleteRoles = {
    UserRole.admin,
    UserRole.founder,
    UserRole.director,
    UserRole.censor,
  };

  static const _types = [
    'WARNING',
    'BLAME',
    'DETENTION',
    'CONVOCATION',
    'EXCLUSION',
  ];

  bool _loading = true;
  String? _loadError;
  List<dynamic> _rows = [];
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _classes = [];

  String? _filterClassId;
  String? _filterType;
  bool _busy = false;

  bool get _isParent => ref.read(authProvider).role == UserRole.parent;
  bool get _isStudent => ref.read(authProvider).role == UserRole.student;

  String _typeLabel(String? type) => switch (type) {
        'WARNING' => 'Avertissement',
        'BLAME' => 'Blâme',
        'DETENTION' => 'Retenue',
        'CONVOCATION' => 'Convocation',
        'EXCLUSION' => 'Exclusion',
        _ => type ?? '—',
      };

  String _severityLabel(String? s) => switch (s) {
        'LOW' => 'Faible',
        'MEDIUM' => 'Moyenne',
        'HIGH' => 'Élevée',
        _ => s ?? '—',
      };

  Color _severityColor(String? s) => switch (s) {
        'LOW' => successGreen,
        'HIGH' => dangerRed,
        _ => warningYellow,
      };

  String _studentName(Map<String, dynamic> r) {
    final student = r['student'] is Map
        ? Map<String, dynamic>.from(r['student'] as Map)
        : null;
    if (student != null) {
      return '${student['firstName'] ?? ''} ${student['lastName'] ?? ''}'
          .trim();
    }
    return r['studentName']?.toString() ?? 'Élève';
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '—';
    try {
      final d = DateTime.parse(raw.toString());
      return DateFormat('dd/MM/yyyy').format(d);
    } catch (_) {
      return raw.toString();
    }
  }

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (!_isParent && !_isStudent) {
      try {
        final raw = await ClassesApiService.getAll(year: currentSchoolYear());
        _classes = raw
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      } catch (_) {
        _classes = [];
      }
    }
    await _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final year = currentSchoolYear();
      if (_isParent) {
        final sid = widget.studentId ??
            ref.read(selectedChildIdProvider) ??
            ref.read(parentChildProvider)?.id;
        if (sid == null || sid.isEmpty) {
          _rows = [];
          _loadError = 'Aucun enfant sélectionné';
        } else {
          _rows = await DisciplineApiService.byStudent(sid);
        }
      } else if (_isStudent) {
        _rows = await DisciplineApiService.mySanctions();
      } else {
        final results = await Future.wait([
          DisciplineApiService.list(
            classId: _filterClassId,
            type: _filterType,
            year: year,
          ),
          DisciplineApiService.stats(year: year),
        ]);
        _rows = results[0] as List<dynamic>;
        _stats = Map<String, dynamic>.from(results[1] as Map);
      }
    } catch (e) {
      _rows = [];
      _stats = {};
      _loadError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmDelete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer'),
        content: const Text('Supprimer cette sanction ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer', style: TextStyle(color: dangerRed)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await DisciplineApiService.delete(id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: dangerRed,
        ),
      );
    }
  }

  Future<void> _openCreateSheet() async {
    String? classId = _filterClassId ??
        (_classes.isNotEmpty ? _classes.first['id']?.toString() : null);
    String? studentId;
    String type = 'WARNING';
    String severity = 'MEDIUM';
    String trimestre = 'T1';
    final reasonCtrl = TextEditingController();
    final dateCtrl = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    final hoursCtrl = TextEditingController(text: '2');
    List<Map<String, dynamic>> students = [];
    var loadingStudents = false;
    String? loadedForClassId;
    String? formError;

    Future<void> loadStudents(StateSetter setModal) async {
      final cid = classId;
      if (cid == null || cid.isEmpty) {
        setModal(() {
          students = [];
          loadedForClassId = null;
        });
        return;
      }
      if (loadedForClassId == cid && !loadingStudents) return;
      setModal(() => loadingStudents = true);
      try {
        final raw = await StudentsApiService.getAll(classId: cid);
        students = raw
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        loadedForClassId = cid;
        if (studentId != null &&
            !students.any((s) => s['id']?.toString() == studentId)) {
          studentId = null;
        }
      } catch (_) {
        students = [];
        loadedForClassId = cid;
      } finally {
        setModal(() => loadingStudents = false);
      }
    }

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            if (classId != null &&
                loadedForClassId != classId &&
                !loadingStudents) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                loadStudents(setModal);
              });
            }
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Nouvelle sanction',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (formError != null)
                      Card(
                        color: const Color(0xFFFFEBEE),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            formError!,
                            style: const TextStyle(color: dangerRed),
                          ),
                        ),
                      ),
                    DropdownButtonFormField<String>(
                      value: classId,
                      decoration: const InputDecoration(labelText: 'Classe'),
                      items: _classes
                          .map(
                            (c) => DropdownMenuItem(
                              value: c['id']?.toString(),
                              child: Text(c['name']?.toString() ?? 'Classe'),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        setModal(() {
                          classId = v;
                          studentId = null;
                          students = [];
                          loadedForClassId = null;
                        });
                        loadStudents(setModal);
                      },
                    ),
                    const SizedBox(height: 8),
                    if (loadingStudents)
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    else
                      DropdownButtonFormField<String>(
                        value: studentId,
                        decoration: const InputDecoration(labelText: 'Élève'),
                        items: students
                            .map(
                              (s) => DropdownMenuItem(
                                value: s['id']?.toString(),
                                child: Text(
                                  '${s['firstName'] ?? ''} ${s['lastName'] ?? ''}'
                                      .trim(),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setModal(() => studentId = v),
                      ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: type,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: _types
                          .map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Text(_typeLabel(t)),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setModal(() => type = v);
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: severity,
                      decoration:
                          const InputDecoration(labelText: 'Gravité'),
                      items: const [
                        DropdownMenuItem(value: 'LOW', child: Text('Faible')),
                        DropdownMenuItem(
                            value: 'MEDIUM', child: Text('Moyenne')),
                        DropdownMenuItem(value: 'HIGH', child: Text('Élevée')),
                      ],
                      onChanged: (v) {
                        if (v != null) setModal(() => severity = v);
                      },
                    ),
                    if (type == 'DETENTION') ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: hoursCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Durée (heures)',
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    TextField(
                      controller: reasonCtrl,
                      decoration: const InputDecoration(labelText: 'Motif'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: dateCtrl,
                      readOnly: true,
                      decoration: const InputDecoration(labelText: 'Date'),
                      onTap: () async {
                        final now = DateTime.now();
                        final d = await showDatePicker(
                          context: ctx,
                          initialDate: now,
                          firstDate: now.subtract(const Duration(days: 365)),
                          lastDate: now.add(const Duration(days: 30)),
                        );
                        if (d != null) {
                          dateCtrl.text = DateFormat('yyyy-MM-dd').format(d);
                          setModal(() {});
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: trimestre,
                      decoration:
                          const InputDecoration(labelText: 'Trimestre'),
                      items: const [
                        DropdownMenuItem(value: 'T1', child: Text('T1')),
                        DropdownMenuItem(value: 'T2', child: Text('T2')),
                        DropdownMenuItem(value: 'T3', child: Text('T3')),
                      ],
                      onChanged: (v) {
                        if (v != null) setModal(() => trimestre = v);
                      },
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _busy
                          ? null
                          : () async {
                              if (classId == null ||
                                  studentId == null ||
                                  reasonCtrl.text.trim().isEmpty) {
                                setModal(() {
                                  formError =
                                      'Classe, élève et motif sont requis';
                                });
                                return;
                              }
                              setState(() => _busy = true);
                              setModal(() => formError = null);
                              try {
                                final payload = <String, dynamic>{
                                  'studentId': studentId,
                                  'classId': classId,
                                  'type': type,
                                  'severity': severity,
                                  'reason': reasonCtrl.text.trim(),
                                  'date': dateCtrl.text,
                                  'trimestre': trimestre,
                                  'year': currentSchoolYear(),
                                };
                                if (type == 'DETENTION') {
                                  payload['durationHours'] =
                                      int.tryParse(hoursCtrl.text.trim()) ?? 2;
                                }
                                await DisciplineApiService.create(payload);
                                if (ctx.mounted) Navigator.pop(ctx);
                                await _load();
                              } catch (e) {
                                setModal(() {
                                  formError = e
                                      .toString()
                                      .replaceFirst('Exception: ', '');
                                });
                              } finally {
                                if (mounted) {
                                  setState(() => _busy = false);
                                }
                              }
                            },
                      child: Text(_busy ? 'Enregistrement…' : 'Enregistrer'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    reasonCtrl.dispose();
    dateCtrl.dispose();
    hoursCtrl.dispose();
  }

  Widget _statsChips() {
    final byType = _stats['byType'] is Map
        ? Map<String, dynamic>.from(_stats['byType'] as Map)
        : <String, dynamic>{};
    final total = _stats['total'] ?? 0;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Chip(
          label: Text('Total : $total'),
          backgroundColor: infoLight,
          labelStyle: const TextStyle(color: primaryBlue, fontSize: 12),
        ),
        ..._types.map((t) {
          final n = byType[t] ?? 0;
          return Chip(
            label: Text('${_typeLabel(t)} : $n'),
            backgroundColor: borderLight,
            labelStyle: const TextStyle(fontSize: 12, color: textMedium),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(authProvider).role;
    final canWrite = role != null && _canWriteRoles.contains(role);
    final canDelete = role != null && _canDeleteRoles.contains(role);
    final isStaff =
        role != UserRole.parent && role != UserRole.student;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discipline'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: canWrite
          ? FloatingActionButton(
              backgroundColor: primaryBlue,
              onPressed: _busy ? null : _openCreateSheet,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  if (_loadError != null)
                    Card(
                      color: const Color(0xFFFFEBEE),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          _loadError!,
                          style: const TextStyle(color: dangerRed),
                        ),
                      ),
                    ),
                  if (isStaff) ...[
                    _statsChips(),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      value: _filterClassId,
                      decoration: const InputDecoration(
                        labelText: 'Filtrer par classe',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Toutes les classes'),
                        ),
                        ..._classes.map(
                          (c) => DropdownMenuItem(
                            value: c['id']?.toString(),
                            child: Text(c['name']?.toString() ?? 'Classe'),
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        setState(() => _filterClassId = v);
                        _load();
                      },
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      children: [
                        FilterChip(
                          label: const Text('Tous'),
                          selected: _filterType == null,
                          onSelected: (_) {
                            setState(() => _filterType = null);
                            _load();
                          },
                        ),
                        ..._types.map(
                          (t) => FilterChip(
                            label: Text(_typeLabel(t)),
                            selected: _filterType == t,
                            onSelected: (_) {
                              setState(() => _filterType = t);
                              _load();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_rows.isEmpty && _loadError == null)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: Text(
                          'Aucune sanction enregistrée',
                          style: TextStyle(color: textGrey),
                        ),
                      ),
                    ),
                  ..._rows.map((raw) {
                    final r = Map<String, dynamic>.from(raw as Map);
                    final id = r['id']?.toString();
                    final type = r['type']?.toString();
                    final severity = r['severity']?.toString();
                    return Card(
                      child: ListTile(
                        title: Text(_studentName(r)),
                        subtitle: Text(
                          '${_typeLabel(type)} · ${_severityLabel(severity)}\n'
                          '${r['reason'] ?? ''}\n'
                          '${_formatDate(r['date'])}',
                        ),
                        isThreeLine: true,
                        leading: CircleAvatar(
                          backgroundColor:
                              _severityColor(severity).withValues(alpha: 0.15),
                          child: Icon(
                            Icons.gavel,
                            size: 18,
                            color: _severityColor(severity),
                          ),
                        ),
                        trailing: canDelete && id != null
                            ? IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: dangerRed),
                                onPressed: () => _confirmDelete(id),
                              )
                            : null,
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
