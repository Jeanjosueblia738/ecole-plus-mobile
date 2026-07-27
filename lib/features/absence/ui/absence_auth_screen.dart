import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/security/user_role.dart';
import '../../../core/services/absence_auth_api_service.dart';
import '../../../core/theme/app_colors.dart';

class AbsenceAuthScreen extends ConsumerStatefulWidget {
  const AbsenceAuthScreen({super.key});

  @override
  ConsumerState<AbsenceAuthScreen> createState() => _AbsenceAuthScreenState();
}

class _AbsenceAuthScreenState extends ConsumerState<AbsenceAuthScreen> {
  bool _loading = true;
  List<dynamic> _rows = [];
  final _startCtrl = TextEditingController();
  final _endCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  String? _studentId;
  bool _busy = false;
  /// SHORT ≤3 j · LEAVE ≤90 j (personnel uniquement)
  String _category = 'SHORT';

  static const _studentValidators = {
    UserRole.surveillant,
    UserRole.censor,
  };
  static const _staffValidators = {
    UserRole.admin,
    UserRole.founder,
    UserRole.director,
  };
  String? _listError;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _listError = null;
    });
    try {
      _rows = await AbsenceAuthApiService.list();
    } catch (e) {
      _rows = [];
      _listError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _startCtrl.dispose();
    _endCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  int? _durationDays() {
    try {
      final a = DateTime.parse(_startCtrl.text);
      final b = DateTime.parse(_endCtrl.text);
      return b.difference(DateTime(a.year, a.month, a.day)).inDays + 1;
    } catch (_) {
      return null;
    }
  }

  int get _maxDays {
    final role = ref.read(authProvider).role;
    final isStudentSide =
        role == UserRole.parent || role == UserRole.student;
    if (isStudentSide) return 3;
    return _category == 'LEAVE' ? 90 : 3;
  }

  Future<void> _pickDate(TextEditingController ctrl) async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 7)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (d != null) {
      ctrl.text = DateFormat('yyyy-MM-dd').format(d);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(authProvider).role;
    final isParent = role == UserRole.parent;
    final isStudent = role == UserRole.student;
    final canRequestStudent = isParent || isStudent;
    final canRequestStaff = !isParent && !isStudent && role != null;
    final canValidateStudent =
        role != null && _studentValidators.contains(role);
    final canValidateStaff = role != null && _staffValidators.contains(role);
    final days = _durationDays();
    final maxDays = _maxDays;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Autorisations d’absence'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_listError != null)
                    Card(
                      color: const Color(0xFFFFEBEE),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          _listError!,
                          style: const TextStyle(color: dangerRed),
                        ),
                      ),
                    ),
                  if (canRequestStudent || canRequestStaff)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              canRequestStudent
                                  ? 'Nouvelle demande élève'
                                  : 'Nouvelle demande personnel',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (canRequestStaff) ...[
                              const SizedBox(height: 8),
                              SegmentedButton<String>(
                                segments: const [
                                  ButtonSegment(
                                    value: 'SHORT',
                                    label: Text('Courte ≤3 j'),
                                  ),
                                  ButtonSegment(
                                    value: 'LEAVE',
                                    label: Text('Congé RH ≤90 j'),
                                  ),
                                ],
                                selected: {_category},
                                onSelectionChanged: (s) {
                                  setState(() => _category = s.first);
                                },
                              ),
                            ],
                            const SizedBox(height: 8),
                            if (isParent)
                              TextField(
                                decoration: const InputDecoration(
                                  labelText: 'ID élève (si plusieurs enfants)',
                                ),
                                onChanged: (v) => _studentId = v.trim(),
                              ),
                            TextField(
                              controller: _startCtrl,
                              readOnly: true,
                              decoration:
                                  const InputDecoration(labelText: 'Début'),
                              onTap: () => _pickDate(_startCtrl),
                            ),
                            TextField(
                              controller: _endCtrl,
                              readOnly: true,
                              decoration:
                                  const InputDecoration(labelText: 'Fin'),
                              onTap: () => _pickDate(_endCtrl),
                            ),
                            TextField(
                              controller: _reasonCtrl,
                              decoration:
                                  const InputDecoration(labelText: 'Motif'),
                              maxLines: 2,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              days == null
                                  ? 'Maximum $maxDays jours'
                                  : '$days jour(s) — max $maxDays',
                              style: TextStyle(
                                fontSize: 12,
                                color: days != null && days > maxDays
                                    ? dangerRed
                                    : textGrey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            FilledButton(
                              onPressed: _busy ||
                                      (days != null && days > maxDays)
                                  ? null
                                  : () async {
                                      setState(() => _busy = true);
                                      try {
                                        if (canRequestStudent) {
                                          await AbsenceAuthApiService
                                              .createStudent(
                                            studentId: _studentId,
                                            startDate: _startCtrl.text,
                                            endDate: _endCtrl.text,
                                            reason: _reasonCtrl.text.trim(),
                                          );
                                        } else {
                                          await AbsenceAuthApiService
                                              .createStaff(
                                            startDate: _startCtrl.text,
                                            endDate: _endCtrl.text,
                                            reason: _reasonCtrl.text.trim(),
                                            category: _category,
                                          );
                                        }
                                        _reasonCtrl.clear();
                                        await _load();
                                      } catch (e) {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(this.context)
                                            .showSnackBar(
                                          SnackBar(content: Text('$e')),
                                        );
                                      } finally {
                                        if (mounted) {
                                          setState(() => _busy = false);
                                        }
                                      }
                                    },
                              child: Text(_busy ? 'Envoi…' : 'Envoyer'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  ..._rows.map((raw) {
                    final r = Map<String, dynamic>.from(raw as Map);
                    final status = r['status']?.toString() ?? '';
                    final kind = r['kind']?.toString() ?? '';
                    final category = r['category']?.toString() ?? 'SHORT';
                    final canDecide = status == 'PENDING' &&
                        ((kind == 'STUDENT' && canValidateStudent) ||
                            (kind == 'STAFF' && canValidateStaff));
                    final student = r['student'] is Map
                        ? Map<String, dynamic>.from(r['student'] as Map)
                        : null;
                    final excused = r['excusedOccurrences'] ??
                        (r['excusedOccurrenceIds'] is List
                            ? (r['excusedOccurrenceIds'] as List).length
                            : null);
                    return Card(
                      child: ListTile(
                        title: Text(
                          kind == 'STUDENT'
                              ? 'Élève — ${student?['firstName'] ?? ''} ${student?['lastName'] ?? ''}'
                              : 'Staff — ${r['requesterName'] ?? ''}',
                        ),
                        subtitle: Text(
                          '${r['durationDays']} j · $status'
                          '${kind == 'STAFF' ? (category == 'LEAVE' ? ' · Congé RH' : ' · Courte') : ''}'
                          '${excused != null && excused != 0 ? ' · $excused séance(s) excusée(s)' : ''}\n'
                          '${r['reason'] ?? ''}',
                        ),
                        isThreeLine: true,
                        trailing: canDecide
                            ? Wrap(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.check,
                                        color: successGreen),
                                    onPressed: () async {
                                      try {
                                        final res =
                                            await AbsenceAuthApiService.approve(
                                                r['id'].toString());
                                        if (!mounted) return;
                                        final warn =
                                            res['warning']?.toString();
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              warn ??
                                                  'Demande approuvée'
                                                      '${res['excusedOccurrences'] != null ? ' · ${res['excusedOccurrences']} séance(s) excusée(s)' : ''}',
                                            ),
                                            backgroundColor: warn != null
                                                ? Colors.orange
                                                : successGreen,
                                          ),
                                        );
                                        await _load();
                                      } catch (e) {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              e
                                                  .toString()
                                                  .replaceFirst(
                                                      'Exception: ', ''),
                                            ),
                                            backgroundColor: dangerRed,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close,
                                        color: dangerRed),
                                    onPressed: () async {
                                      try {
                                        await AbsenceAuthApiService.reject(
                                            r['id'].toString());
                                        await _load();
                                      } catch (e) {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              e
                                                  .toString()
                                                  .replaceFirst(
                                                      'Exception: ', ''),
                                            ),
                                            backgroundColor: dangerRed,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ],
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
