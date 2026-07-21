import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/attendance_provider.dart';
import '../../../core/providers/parent_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../student/data/attendance_store.dart';
import '../../parent/ui/justify_absence_screen.dart';

class AttendanceHistoryScreen extends ConsumerStatefulWidget {
  final List<String> history;
  final String? studentId;
  final String? studentName;
  final String? className;

  const AttendanceHistoryScreen({
    super.key,
    this.history = const [],
    this.studentId,
    this.studentName,
    this.className,
  });

  @override
  ConsumerState<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState
    extends ConsumerState<AttendanceHistoryScreen> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      var studentId = widget.studentId;
      var studentName = widget.studentName ?? '';
      var className = widget.className ?? '';
      if (studentId == null || studentId.isEmpty) {
        final child = await ref.read(parentChildAsyncProvider.future);
        studentId = child?.id;
        studentName = child?.fullName ?? '';
        className = child?.className ?? '';
      }
      if (studentId == null || studentId.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'Aucun élève sélectionné';
        });
        return;
      }
      await ref.read(attendanceProvider.notifier).loadForStudent(
            studentId,
            studentName: studentName,
            className: className,
          );
      final attErr = ref.read(attendanceProvider.notifier).error;
      if (attErr != null) _error = attErr;
    } catch (_) {
      _error = 'Impossible de charger les absences';
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final studentId = widget.studentId ?? ref.watch(parentChildProvider)?.id;
    final records = studentId == null
        ? ref.watch(attendanceProvider)
        : ref.watch(absencesByStudentProvider(studentId));

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Historique des absences'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: const TextStyle(color: textGrey)),
                      TextButton(onPressed: _load, child: const Text('Réessayer')),
                    ],
                  ),
                )
              : records.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            ref.read(attendanceProvider.notifier).error != null
                                ? Icons.error_outline
                                : Icons.check_circle_outline,
                            size: 64,
                            color:
                                ref.read(attendanceProvider.notifier).error !=
                                        null
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFF16A34A),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            ref.read(attendanceProvider.notifier).error ??
                                'Aucune absence enregistrée',
                            style: const TextStyle(color: Color(0xFF6B7280)),
                            textAlign: TextAlign.center,
                          ),
                          if (ref.read(attendanceProvider.notifier).error !=
                              null)
                            TextButton(
                                onPressed: _load,
                                child: const Text('Réessayer')),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: records.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final record = records[index];
                        return _AbsenceCard(record: record);
                      },
                    ),
    );
  }
}

class _AbsenceCard extends ConsumerWidget {
  final AttendanceRecord record;

  const _AbsenceCard({required this.record});

  Color _statusColor(String status) {
    return switch (status) {
      'Justifiée' => const Color(0xFF16A34A),
      'En attente' => const Color(0xFFD97706),
      'Retard' => const Color(0xFFD97706),
      _ => const Color(0xFFDC2626),
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _statusColor(record.status);
    final canJustify = record.status == 'Absent';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  record.studentName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  record.status,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('${record.subject} • ${record.date}',
              style: const TextStyle(color: textGrey, fontSize: 13)),
          if (record.justificationMotif != null) ...[
            const SizedBox(height: 6),
            Text('Motif: ${record.justificationMotif}',
                style: const TextStyle(fontSize: 13)),
          ],
          if (canJustify) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => JustifyAbsenceScreen(record: record),
                    ),
                  );
                },
                child: const Text('Justifier'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
