import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/attendance_provider.dart';
import '../../../core/session/user_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../student/data/attendance_store.dart';

class AdminValidationScreen extends ConsumerWidget {
  const AdminValidationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!UserSession.isAdmin) {
      return const Scaffold(body: Center(child: Text('Accès refusé')));
    }

    final pending = ref.watch(pendingJustificationsProvider);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Justifications à valider'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: pending.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 64, color: Color(0xFF16A34A)),
                  SizedBox(height: 12),
                  Text('Aucune justification en attente',
                      style: TextStyle(color: textGrey, fontSize: 15)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: pending.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final record = pending[index];
                return _JustificationCard(record: record);
              },
            ),
    );
  }
}

// ── Carte justification ────────────────────────────────────────────────────
class _JustificationCard extends ConsumerWidget {
  final AttendanceRecord record;
  const _JustificationCard({required this.record});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: warningYellow.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── En-tête ──────────────────────────────────────────
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: primaryBlue.withValues(alpha: 0.1),
                child: Text(
                  record.studentName[0].toUpperCase(),
                  style: const TextStyle(
                      color: primaryBlue, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(record.studentName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    Text('${record.className} • ${record.subject}',
                        style: const TextStyle(color: textGrey, fontSize: 13)),
                  ],
                ),
              ),
              // Badge En attente
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF9C3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('En attente',
                    style: TextStyle(
                        color: Color(0xFF92400E),
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Infos absence ─────────────────────────────────────
          _InfoRow(Icons.calendar_today_outlined,
              '${record.date} • ${record.duration}'),
          if (record.justificationMotif != null)
            _InfoRow(
                Icons.comment_outlined, 'Motif : ${record.justificationMotif}'),

          const SizedBox(height: 14),

          // ── Actions ───────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Refuser'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: dangerRed,
                    side: BorderSide(color: dangerRed.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Justification refusée'),
                        backgroundColor: dangerRed,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check, size: 16, color: Colors.white),
                  label: const Text('Valider',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: successGreen,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    await ref
                        .read(attendanceProvider.notifier)
                        .validateJustification(record.id);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Justification validée ✓'),
                        backgroundColor: Color(0xFF16A34A),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: textGrey),
          const SizedBox(width: 6),
          Expanded(
              child: Text(text,
                  style: const TextStyle(color: textGrey, fontSize: 13))),
        ],
      ),
    );
  }
}
