import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/attendance_provider.dart';
import '../../../core/providers/student_provider.dart';
import '../../../core/theme/app_colors.dart';

// Écran migré vers Riverpod — remplace l'ancienne version avec stores statiques
class StudentStatsScreen extends ConsumerWidget {
  const StudentStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final students = ref.watch(studentProvider);
    final stats = ref.watch(attendanceStatsProvider);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Statistiques élèves'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _StatRow('Élèves inscrits', students.length, primaryBlue),
            _StatRow('Total absences', stats['total'] ?? 0, dangerRed),
            _StatRow('Justifiées', stats['justifiee'] ?? 0, successGreen),
            _StatRow('En attente', stats['enAttente'] ?? 0, warningYellow),
            _StatRow('Non justifiées', stats['absent'] ?? 0, dangerRed),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatRow(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 40,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 14),
          Expanded(
              child: Text(label,
                  style: const TextStyle(fontSize: 14, color: textDark))),
          Text(
            value.toString(),
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
