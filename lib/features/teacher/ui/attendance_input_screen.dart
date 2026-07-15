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
  bool _loadingStudents = true;
  late final TextEditingController _subjectCtrl;

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
        'records': records,
      });
      if (!mounted) return;
      final absents = result['absents'] ??
          records.where((r) => r['status'] == 'ABSENT').length;
      _showConfirmDialog(absents as int, students.length);
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

  void _showConfirmDialog(int absents, int total) {
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
          'Données synchronisées avec l\'école.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
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
                ),
                const SizedBox(height: 8),
                Text(
                  'Absents: $absentCount · Retards: $lateCount',
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
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting || _loadingStudents ? null : _submit,
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
            ),
          ),
        ],
      ),
    );
  }
}
