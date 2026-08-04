import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/security/user_role.dart';
import '../../../core/services/classes_api_service.dart';
import '../../../core/services/conseil_api_service.dart';
import '../../../core/services/students_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/school_year.dart';

class _ConseilRow {
  _ConseilRow({
    required this.studentId,
    required this.name,
    this.mention,
    this.decision,
    this.appreciation = '',
  });

  final String studentId;
  final String name;
  String? mention;
  String? decision;
  String appreciation;
  bool dirty = false;
}

class ConseilBoardScreen extends ConsumerStatefulWidget {
  const ConseilBoardScreen({super.key});

  @override
  ConsumerState<ConseilBoardScreen> createState() => _ConseilBoardScreenState();
}

class _ConseilBoardScreenState extends ConsumerState<ConseilBoardScreen> {
  static const _canWriteRoles = {
    UserRole.admin,
    UserRole.founder,
    UserRole.director,
    UserRole.censor,
  };

  static const _mentions = [
    ('TRES_BIEN', 'Très bien'),
    ('BIEN', 'Bien'),
    ('ASSEZ_BIEN', 'Assez bien'),
    ('PASSABLE', 'Passable'),
    ('MEDIOCRE', 'Médiocre'),
    ('NIL', '—'),
  ];

  static const _decisions = [
    ('PASSAGE', 'Passage'),
    ('REDOUBLEMENT', 'Redoublement'),
    ('CONDITIONAL', 'Passage conditionnel'),
  ];

  bool _loading = true;
  bool _saving = false;
  String? _loadError;
  List<Map<String, dynamic>> _classes = [];
  String? _classId;
  String _trimestre = 'T1';
  List<_ConseilRow> _rows = [];
  final Map<String, TextEditingController> _appreciationCtrls = {};

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    for (final c in _appreciationCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _ctrlFor(_ConseilRow row) {
    return _appreciationCtrls.putIfAbsent(
      row.studentId,
      () => TextEditingController(text: row.appreciation),
    );
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final raw = await ClassesApiService.getAll(year: currentSchoolYear());
      _classes =
          raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      if (_classes.isNotEmpty) {
        _classId ??= _classes.first['id']?.toString();
      }
      if (_classId != null) {
        await _loadBoard(showSpinner: false);
      } else {
        _rows = [];
      }
    } catch (e) {
      _loadError = e.toString().replaceFirst('Exception: ', '');
      _rows = [];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadBoard({bool showSpinner = true}) async {
    final classId = _classId;
    if (classId == null || classId.isEmpty) {
      setState(() {
        _rows = [];
        _loadError = 'Sélectionnez une classe';
      });
      return;
    }
    if (showSpinner) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }
    try {
      final year = currentSchoolYear();
      final studentsRaw =
          await StudentsApiService.getAll(classId: classId);
      final conseilRaw = await ConseilApiService.list(
        classId: classId,
        trimestre: _trimestre,
        year: year,
      );

      final students = studentsRaw
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      // API may return { student, decision } or flat decision rows.
      final byStudentId = <String, Map<String, dynamic>>{};
      for (final raw in conseilRaw) {
        final item = Map<String, dynamic>.from(raw as Map);
        if (item['decision'] is Map && item['student'] is Map) {
          final student = Map<String, dynamic>.from(item['student'] as Map);
          final decision =
              Map<String, dynamic>.from(item['decision'] as Map? ?? {});
          final sid = student['id']?.toString();
          if (sid != null) byStudentId[sid] = decision;
        } else if (item['studentId'] != null) {
          byStudentId[item['studentId'].toString()] = item;
        } else if (item['student'] is Map) {
          final student = Map<String, dynamic>.from(item['student'] as Map);
          final sid = student['id']?.toString();
          if (sid != null && item['decision'] == null) {
            // merged null decision — skip
          } else if (sid != null && item['decision'] is Map) {
            byStudentId[sid] =
                Map<String, dynamic>.from(item['decision'] as Map);
          }
        }
      }

      for (final c in _appreciationCtrls.values) {
        c.dispose();
      }
      _appreciationCtrls.clear();

      final rows = <_ConseilRow>[];
      for (final s in students) {
        final sid = s['id']?.toString();
        if (sid == null) continue;
        final dec = byStudentId[sid];
        final mentionRaw = dec?['mention']?.toString();
        final decisionRaw = dec?['decision']?.toString();
        final appreciation = dec?['appreciation']?.toString() ?? '';
        rows.add(
          _ConseilRow(
            studentId: sid,
            name: '${s['firstName'] ?? ''} ${s['lastName'] ?? ''}'.trim(),
            mention: mentionRaw == null ||
                    mentionRaw.isEmpty ||
                    mentionRaw == 'NIL'
                ? null
                : mentionRaw,
            decision: decisionRaw == null || decisionRaw.isEmpty
                ? null
                : decisionRaw,
            appreciation: appreciation,
          ),
        );
      }
      rows.sort((a, b) => a.name.compareTo(b.name));
      _rows = rows;
      _loadError = null;
    } catch (e) {
      _rows = [];
      _loadError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveDirty() async {
    final classId = _classId;
    if (classId == null) return;
    final dirty = _rows.where((r) => r.dirty).toList();
    if (dirty.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune modification à enregistrer')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final year = currentSchoolYear();
      for (final row in dirty) {
        await ConseilApiService.upsert({
          'studentId': row.studentId,
          'classId': classId,
          'trimestre': _trimestre,
          'year': year,
          if (row.mention != null && row.mention!.isNotEmpty)
            'mention': row.mention,
          if (row.decision != null && row.decision!.isNotEmpty)
            'decision': row.decision,
          'appreciation': row.appreciation.trim().isEmpty
              ? null
              : row.appreciation.trim(),
        });
        row.dirty = false;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${dirty.length} décision(s) enregistrée(s)'),
          backgroundColor: successGreen,
        ),
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: dangerRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(authProvider).role;
    final canWrite = role != null && _canWriteRoles.contains(role);
    final dirtyCount = _rows.where((r) => r.dirty).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conseil de classe'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          if (canWrite)
            TextButton(
              onPressed: _saving || dirtyCount == 0 ? null : _saveDirty,
              child: Text(
                _saving ? '…' : 'Enregistrer${dirtyCount > 0 ? ' ($dirtyCount)' : ''}',
                style: TextStyle(
                  color: _saving || dirtyCount == 0
                      ? Colors.white54
                      : Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      if (!canWrite)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Lecture seule — seuls admin, fondateur, directeur et censeur peuvent enregistrer.',
                            style: TextStyle(fontSize: 12, color: textGrey),
                          ),
                        ),
                      DropdownButtonFormField<String>(
                        value: _classId,
                        decoration: const InputDecoration(
                          labelText: 'Classe',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: _classes
                            .map(
                              (c) => DropdownMenuItem(
                                value: c['id']?.toString(),
                                child: Text(c['name']?.toString() ?? 'Classe'),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          setState(() => _classId = v);
                          _loadBoard();
                        },
                      ),
                      const SizedBox(height: 10),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'T1', label: Text('T1')),
                          ButtonSegment(value: 'T2', label: Text('T2')),
                          ButtonSegment(value: 'T3', label: Text('T3')),
                        ],
                        selected: {_trimestre},
                        onSelectionChanged: (s) {
                          setState(() => _trimestre = s.first);
                          _loadBoard();
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Année ${currentSchoolYear()}',
                          style:
                              const TextStyle(fontSize: 12, color: textGrey),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _rows.isEmpty
                      ? const Center(
                          child: Text(
                            'Aucun élève dans cette classe',
                            style: TextStyle(color: textGrey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: _rows.length,
                          itemBuilder: (context, i) {
                            final row = _rows[i];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            row.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        if (row.dirty)
                                          const Icon(Icons.edit,
                                              size: 14, color: warningYellow),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<String?>(
                                      value: row.mention,
                                      decoration: const InputDecoration(
                                        labelText: 'Mention',
                                        isDense: true,
                                      ),
                                      items: [
                                        const DropdownMenuItem(
                                          value: null,
                                          child: Text('—'),
                                        ),
                                        ..._mentions
                                            .where((m) => m.$1 != 'NIL')
                                            .map(
                                              (m) => DropdownMenuItem(
                                                value: m.$1,
                                                child: Text(m.$2),
                                              ),
                                            ),
                                      ],
                                      onChanged: canWrite
                                          ? (v) {
                                              setState(() {
                                                row.mention = v;
                                                row.dirty = true;
                                              });
                                            }
                                          : null,
                                    ),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<String?>(
                                      value: row.decision,
                                      decoration: const InputDecoration(
                                        labelText: 'Décision',
                                        isDense: true,
                                      ),
                                      items: [
                                        const DropdownMenuItem(
                                          value: null,
                                          child: Text('—'),
                                        ),
                                        ..._decisions.map(
                                          (d) => DropdownMenuItem(
                                            value: d.$1,
                                            child: Text(d.$2),
                                          ),
                                        ),
                                      ],
                                      onChanged: canWrite
                                          ? (v) {
                                              setState(() {
                                                row.decision = v;
                                                row.dirty = true;
                                              });
                                            }
                                          : null,
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: _ctrlFor(row),
                                      enabled: canWrite,
                                      decoration: const InputDecoration(
                                        labelText: 'Appréciation',
                                        isDense: true,
                                      ),
                                      maxLines: 2,
                                      onChanged: canWrite
                                          ? (v) {
                                              row.appreciation = v;
                                              if (!row.dirty) {
                                                setState(() => row.dirty = true);
                                              }
                                            }
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                if (canWrite)
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: FilledButton(
                        onPressed:
                            _saving || dirtyCount == 0 ? null : _saveDirty,
                        child: Text(
                          _saving
                              ? 'Enregistrement…'
                              : 'Enregistrer${dirtyCount > 0 ? ' ($dirtyCount)' : ''}',
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
