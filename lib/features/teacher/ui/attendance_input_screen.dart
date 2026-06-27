import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/attendance_provider.dart';
import '../../../core/providers/student_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/sms_service.dart';
import '../../../services/sms_template_service.dart';
import '../../student/data/attendance_store.dart';
import '../../student/data/student.dart';

class AttendanceInputScreen extends ConsumerStatefulWidget {
  final String className;
  final String subject;
  final String duration;

  const AttendanceInputScreen({
    super.key,
    required this.className,
    required this.subject,
    required this.duration,
  });

  @override
  ConsumerState<AttendanceInputScreen> createState() =>
      _AttendanceInputScreenState();
}

class _AttendanceInputScreenState extends ConsumerState<AttendanceInputScreen> {
  // id élève → 'present' | 'absent' | 'late'
  final Map<String, String> _status = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final students =
        ref.read(studentProvider.notifier).byClass(widget.className);
    for (final s in students) {
      _status[s.id] = 'present';
    }
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    final students =
        ref.read(studentProvider.notifier).byClass(widget.className);
    final formattedDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
    final newRecords = <AttendanceRecord>[];

    for (final student in students) {
      final st = _status[student.id] ?? 'present';
      if (st == 'present') continue;

      final record = AttendanceRecord(
        id: '${student.id}_${DateTime.now().millisecondsSinceEpoch}',
        studentId: student.id,
        studentName: student.fullName,
        className: widget.className,
        subject: widget.subject,
        date: formattedDate,
        duration: widget.duration,
        isLate: st == 'late',
        status: 'Absent',
      );
      newRecords.add(record);

      // Notification SMS au parent
      await SmsService.sendSms(
        recipient: student.parentPhone,
        message: SmsTemplateService.absenceNotification(
          studentName: student.fullName,
          subject: widget.subject,
          date: formattedDate,
          duration: widget.duration,
        ),
      );
    }

    // Mise à jour du provider Riverpod
    await ref.read(attendanceProvider.notifier).addRecords(newRecords);

    setState(() => _isSubmitting = false);
    if (!mounted) return;

    _showConfirmDialog(newRecords.length, students.length);
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
          'Parents notifiés par SMS.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // ferme dialog
              Navigator.pop(context); // retour dashboard
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final students =
        ref.watch(studentProvider.notifier).byClass(widget.className);

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
          // ── En-tête séance ──────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: primaryBlue.withValues(alpha: 0.06),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.class_,
                        size: 16, color: Color(0xFF6B7280)),
                    const SizedBox(width: 6),
                    Text('Classe : ${widget.className}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.book, size: 16, color: Color(0xFF6B7280)),
                    const SizedBox(width: 6),
                    Text('${widget.subject} • ${widget.duration}',
                        style: const TextStyle(color: Color(0xFF6B7280))),
                  ],
                ),
              ],
            ),
          ),

          // ── Compteurs rapides ────────────────────────────────────────
          if (absentCount > 0 || lateCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  if (absentCount > 0)
                    _StatChip(
                        label:
                            '$absentCount absent${absentCount > 1 ? 's' : ''}',
                        color: dangerRed),
                  if (absentCount > 0 && lateCount > 0)
                    const SizedBox(width: 8),
                  if (lateCount > 0)
                    _StatChip(
                        label: '$lateCount retard${lateCount > 1 ? 's' : ''}',
                        color: warningYellow),
                ],
              ),
            ),

          const Divider(height: 1),

          // ── Liste élèves ─────────────────────────────────────────────
          Expanded(
            child: students.isEmpty
                ? Center(
                    child: Text(
                      'Aucun élève dans la classe ${widget.className}',
                      style: const TextStyle(color: Color(0xFF6B7280)),
                    ),
                  )
                : ListView.separated(
                    itemCount: students.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 16),
                    itemBuilder: (context, index) {
                      final student = students[index];
                      final st = _status[student.id] ?? 'present';
                      return _StudentAttendanceTile(
                        student: student,
                        status: st,
                        onChanged: (value) =>
                            setState(() => _status[student.id] = value),
                      );
                    },
                  ),
          ),

          // ── Bouton valider ────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Valider la séance',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tuile élève avec 3 états ───────────────────────────────────────────────
class _StudentAttendanceTile extends StatelessWidget {
  final Student student;
  final String status; // 'present' | 'absent' | 'late'
  final ValueChanged<String> onChanged;

  const _StudentAttendanceTile({
    required this.student,
    required this.status,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _bgColor,
        child: Text(
          student.fullName[0].toUpperCase(),
          style: TextStyle(color: _textColor, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(student.fullName,
          style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: SegmentedButton<String>(
        style: SegmentedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          textStyle: const TextStyle(fontSize: 11),
        ),
        segments: const [
          ButtonSegment(value: 'present', label: Text('Présent')),
          ButtonSegment(value: 'late', label: Text('Retard')),
          ButtonSegment(value: 'absent', label: Text('Absent')),
        ],
        selected: {status},
        onSelectionChanged: (s) => onChanged(s.first),
      ),
    );
  }

  Color get _bgColor => switch (status) {
        'absent' => const Color(0xFFDC2626).withValues(alpha: 0.12),
        'late' => const Color(0xFFFACC15).withValues(alpha: 0.2),
        _ => const Color(0xFF16A34A).withValues(alpha: 0.12),
      };

  Color get _textColor => switch (status) {
        'absent' => const Color(0xFFDC2626),
        'late' => const Color(0xFF92400E),
        _ => const Color(0xFF16A34A),
      };
}

// ── Chip compteur ──────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }
}
