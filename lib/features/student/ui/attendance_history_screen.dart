import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/attendance_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../student/data/attendance_store.dart';
import '../../parent/ui/justify_absence_screen.dart';

// ignore: must_be_immutable
class AttendanceHistoryScreen extends ConsumerWidget {
  // history gardé pour compatibilité — ignoré, on lit depuis le provider
  final List<String> history;

  const AttendanceHistoryScreen({super.key, this.history = const []});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(attendanceProvider);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Historique des absences'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: records.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 64, color: Color(0xFF16A34A)),
                  SizedBox(height: 12),
                  Text('Aucune absence enregistrée',
                      style: TextStyle(color: Color(0xFF6B7280))),
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

// ── Carte absence ──────────────────────────────────────────────────────────
class _AbsenceCard extends ConsumerWidget {
  final AttendanceRecord record;

  const _AbsenceCard({required this.record});

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
          // ── Ligne 1 : élève + badge statut ─────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  record.studentName,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              _StatusBadge(status: record.status, isLate: record.isLate),
            ],
          ),
          const SizedBox(height: 6),

          // ── Ligne 2 : matière + date ────────────────────────────────
          Row(
            children: [
              const Icon(Icons.book_outlined,
                  size: 14, color: Color(0xFF6B7280)),
              const SizedBox(width: 4),
              Text(record.subject,
                  style:
                      const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
              const SizedBox(width: 12),
              const Icon(Icons.calendar_today_outlined,
                  size: 14, color: Color(0xFF6B7280)),
              const SizedBox(width: 4),
              Text('${record.date} • ${record.duration}',
                  style:
                      const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
            ],
          ),

          // ── Motif si justification soumise ──────────────────────────
          if (record.justificationMotif != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Motif : ${record.justificationMotif}',
                style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
              ),
            ),
          ],

          // ── Bouton justifier ────────────────────────────────────────
          if (canJustify) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.edit_note, size: 18),
                label: const Text('Justifier cette absence'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryBlue,
                  side: BorderSide(color: primaryBlue.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => JustifyAbsenceScreen(record: record),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _statusColor(String status) => switch (status) {
        'Justifiée' => const Color(0xFF16A34A),
        'En attente' => const Color(0xFFFACC15),
        _ => const Color(0xFFDC2626),
      };
}

// ── Badge statut ───────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String status;
  final bool isLate;

  const _StatusBadge({required this.status, required this.isLate});

  @override
  Widget build(BuildContext context) {
    final label = status == 'Absent' && isLate ? 'Retard' : status;
    final color = switch (status) {
      'Justifiée' => const Color(0xFF16A34A),
      'En attente' => const Color(0xFF92400E),
      _ => isLate ? const Color(0xFF92400E) : const Color(0xFFDC2626),
    };
    final bg = switch (status) {
      'Justifiée' => const Color(0xFFDCFCE7),
      'En attente' => const Color(0xFFFEF9C3),
      _ => isLate ? const Color(0xFFFEF9C3) : const Color(0xFFFEE2E2),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}
