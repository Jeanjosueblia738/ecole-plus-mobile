import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/student_provider.dart';
import '../../../core/services/attendance_api_service.dart';
import '../../../core/theme/app_colors.dart';

class AttendanceInputScreen extends ConsumerStatefulWidget {
  final String className;
  final String subject;
  final String duration;
  final String? classId;

  const AttendanceInputScreen({
    super.key,
    required this.className,
    required this.subject,
    required this.duration,
    this.classId,
  });

  @override
  ConsumerState<AttendanceInputScreen> createState() =>
      _AttendanceInputScreenState();
}

class _AttendanceInputScreenState extends ConsumerState<AttendanceInputScreen> {
  final Map<String, String> _status = {};
  bool _isSubmitting = false;
  bool _smsSending = false;
  bool _loadingStudents = true;
  bool _appelSaved = false;
  late final TextEditingController _subjectCtrl;
  TimeOfDay _start = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 9, minute: 0);
  String? _resolvedClassId;

  @override
  void initState() {
    super.initState();
    _subjectCtrl = TextEditingController(
      text: widget.subject.isNotEmpty ? widget.subject : '',
    );
    _loadStudents();
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    super.dispose();
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime({required bool start}) async {
    final initial = start ? _start : _end;
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    setState(() {
      if (start) {
        _start = picked;
      } else {
        _end = picked;
      }
      _appelSaved = false;
    });
  }

  Future<void> _loadStudents() async {
    setState(() => _loadingStudents = true);
    await ref.read(studentProvider.notifier).load(classId: widget.classId);
    final students = widget.classId != null && widget.classId!.isNotEmpty
        ? ref.read(studentProvider.notifier).byClassId(widget.classId!)
        : ref.read(studentProvider.notifier).byClass(widget.className);
    for (final s in students) {
      _status[s.id] = 'present';
    }
    if (mounted) setState(() => _loadingStudents = false);
  }

  List<String> get _absentIds => _status.entries
      .where((e) => e.value == 'absent')
      .map((e) => e.key)
      .toList();

  Future<void> _submit() async {
    final subject = _subjectCtrl.text.trim();
    if (subject.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Indiquez la matière'),
        backgroundColor: dangerRed,
      ));
      return;
    }

    final students = widget.classId != null && widget.classId!.isNotEmpty
        ? ref.read(studentProvider.notifier).byClassId(widget.classId!)
        : ref.read(studentProvider.notifier).byClass(widget.className);

    final classId = widget.classId ??
        students.map((s) => s.classId).firstWhere(
              (id) => id != null && id.isNotEmpty,
              orElse: () => null,
            );

    if (classId == null || classId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Classe introuvable — choisissez une classe API'),
        backgroundColor: dangerRed,
      ));
      return;
    }

    setState(() => _isSubmitting = true);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final records = students.map((s) {
      final st = _status[s.id] ?? 'present';
      return {
        'studentId': s.id,
        'status': st == 'late'
            ? 'LATE'
            : st == 'absent'
                ? 'ABSENT'
                : 'PRESENT',
        'isLate': st == 'late',
      };
    }).toList();

    try {
      final result = await AttendanceApiService.bulkCreate({
        'classId': classId,
        'subject': subject,
        'date': today,
        'startTime': _fmt(_start),
        'endTime': _fmt(_end),
        'records': records,
      });
      if (!mounted) return;
      final absents = result['absents'] ??
          records.where((r) => r['status'] == 'ABSENT').length;
      setState(() {
        _appelSaved = true;
        _resolvedClassId = classId;
      });
      _showConfirmDialog(absents as int, students.length, classId, subject);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur appel: $e'),
        backgroundColor: dangerRed,
      ));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _sendSms(String classId, String subject) async {
    if (_absentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Aucun absent à notifier'),
      ));
      return;
    }
    setState(() => _smsSending = true);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    try {
      final data = await AttendanceApiService.notifyAbsents({
        'classId': classId,
        'subject': subject,
        'date': today,
        'startTime': _fmt(_start),
        'endTime': _fmt(_end),
        'studentIds': _absentIds,
      });
      if (!mounted) return;
      final msg = data['message']?.toString() ?? 'SMS traités';
      final sim = data['simulated'] == true
          ? '\n(Mode simulation — configurez SMS_WEBHOOK_URL)'
          : '';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$msg$sim'),
        backgroundColor: const Color(0xFF16A34A),
        duration: const Duration(seconds: 4),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur SMS: $e'),
        backgroundColor: dangerRed,
      ));
    } finally {
      if (mounted) setState(() => _smsSending = false);
    }
  }

  void _showConfirmDialog(
    int absents,
    int total,
    String classId,
    String subject,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF16A34A)),
            SizedBox(width: 8),
            Text('Séance validée'),
          ],
        ),
        content: Text(
          '$total élèves traités\n'
          '$absents absence${absents > 1 ? 's' : ''} enregistrée${absents > 1 ? 's' : ''}\n'
          'Créneau : ${_fmt(_start)} – ${_fmt(_end)}\n\n'
          'Envoyer un SMS aux parents des absents ?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Plus tard'),
          ),
          if (absents > 0)
            ElevatedButton.icon(
              onPressed: _smsSending
                  ? null
                  : () async {
                      Navigator.pop(context);
                      await _sendSms(classId, subject);
                      if (mounted) Navigator.pop(context);
                    },
              icon: const Icon(Icons.sms_outlined, size: 18),
              label: Text('SMS parents ($absents)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEA580C),
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final students = widget.classId != null && widget.classId!.isNotEmpty
        ? ref.watch(studentProvider.notifier).byClassId(widget.classId!)
        : ref.watch(studentProvider.notifier).byClass(widget.className);

    final absentCount = _status.values.where((s) => s == 'absent').length;
    final lateCount = _status.values.where((s) => s == 'late').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Faire l\'appel'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: primaryBlue.withValues(alpha: 0.06),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Classe : ${widget.className.isEmpty ? '—' : widget.className}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Matière *',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  controller: _subjectCtrl,
                  onChanged: (_) => setState(() => _appelSaved = false),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickTime(start: true),
                        icon: const Icon(Icons.schedule, size: 16),
                        label: Text('Début ${_fmt(_start)}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickTime(start: false),
                        icon: const Icon(Icons.schedule, size: 16),
                        label: Text('Fin ${_fmt(_end)}'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Absents: $absentCount · Retards: $lateCount'
                  '${_appelSaved ? ' · Appel enregistré' : ''}',
                  style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loadingStudents
                ? const Center(child: CircularProgressIndicator())
                : students.isEmpty
                    ? const Center(child: Text('Aucun élève'))
                    : ListView.builder(
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          final s = students[index];
                          final st = _status[s.id] ?? 'present';
                          return ListTile(
                            tileColor: st == 'absent'
                                ? const Color(0xFFFEF2F2)
                                : null,
                            title: Text(s.fullName),
                            subtitle: Text(st == 'present'
                                ? 'Présent'
                                : st == 'late'
                                    ? 'En retard'
                                    : 'Absent'),
                            trailing: ToggleButtons(
                              isSelected: [
                                st == 'present',
                                st == 'late',
                                st == 'absent',
                              ],
                              onPressed: (i) {
                                setState(() {
                                  _status[s.id] = i == 0
                                      ? 'present'
                                      : i == 1
                                          ? 'late'
                                          : 'absent';
                                  _appelSaved = false;
                                });
                              },
                              children: const [
                                Icon(Icons.check, size: 18),
                                Icon(Icons.schedule, size: 18),
                                Icon(Icons.close, size: 18),
                              ],
                            ),
                          );
                        },
                      ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          _isSubmitting || _loadingStudents ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('Valider l\'appel'),
                    ),
                  ),
                  if (_appelSaved &&
                      _absentIds.isNotEmpty &&
                      _resolvedClassId != null) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _smsSending
                            ? null
                            : () => _sendSms(
                                  _resolvedClassId!,
                                  _subjectCtrl.text.trim(),
                                ),
                        icon: _smsSending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.sms_outlined),
                        label: Text(
                            'SMS parents (${_absentIds.length} absent${_absentIds.length > 1 ? 's' : ''})'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEA580C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
