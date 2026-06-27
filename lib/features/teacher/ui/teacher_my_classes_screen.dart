import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/teacher_provider.dart';
import '../../../core/providers/student_provider.dart';
import '../../../core/theme/app_colors.dart';
import 'teacher_class_detail_screen.dart';

class TeacherMyClassesScreen extends ConsumerWidget {
  const TeacherMyClassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classStats = ref.watch(teacherClassStatsProvider);
    final allStudents = ref.watch(studentProvider);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Mes classes'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: classStats.isEmpty
          ? const Center(
              child: Text('Aucune classe assignée',
                  style: TextStyle(color: textGrey)))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: classStats.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final cs = classStats[index];
                final students = allStudents
                    .where((s) => s.className == cs.className)
                    .toList();
                return _ClassDetailCard(
                  stats: cs,
                  studentCount: students.length,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TeacherClassDetailScreen(
                        className: cs.className,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _ClassDetailCard extends StatelessWidget {
  final ClassStats stats;
  final int studentCount;
  final VoidCallback onTap;

  const _ClassDetailCard({
    required this.stats,
    required this.studentCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final avg = stats.moyenneClasse;
    final avgColor = avg == null
        ? textGrey
        : avg >= 10
            ? successGreen
            : dangerRed;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── En-tête ──────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.class_, color: primaryBlue, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    stats.className,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
                const Icon(Icons.chevron_right, color: textGrey),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // ── Stats 3 colonnes ──────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MiniStat(
                  label: 'Élèves',
                  value: '$studentCount',
                  icon: Icons.people_outline,
                  color: primaryBlue,
                ),
                _MiniStat(
                  label: 'Absences',
                  value: '${stats.absenceCount}',
                  icon: Icons.event_busy_outlined,
                  color: dangerRed,
                ),
                _MiniStat(
                  label: 'Moyenne',
                  value: avg != null ? avg.toStringAsFixed(1) : '—',
                  icon: Icons.grade_outlined,
                  color: avgColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: textGrey)),
      ],
    );
  }
}
