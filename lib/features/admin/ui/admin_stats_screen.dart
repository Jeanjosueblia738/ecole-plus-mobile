import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/attendance_provider.dart';
import '../../../core/providers/student_provider.dart';
import '../../../core/providers/grade_provider.dart';
import '../../../core/providers/class_provider.dart';
import '../../../core/theme/app_colors.dart';

class AdminStatsScreen extends ConsumerWidget {
  const AdminStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final students = ref.watch(studentProvider);
    final absences = ref.watch(attendanceProvider);
    final grades = ref.watch(gradeProvider);
    final classes = ref.watch(classProvider);
    final stats = ref.watch(attendanceStatsProvider);

    // Taux de justification
    final totalAbs = absences.length;
    final justified = stats['justifiee'] ?? 0;
    final tauxJustif =
        totalAbs > 0 ? (justified / totalAbs * 100).toStringAsFixed(1) : '0.0';

    // Moyenne générale globale
    final avgGlobal = grades.isEmpty
        ? 0.0
        : grades.fold(0.0, (s, g) => s + g.value) / grades.length;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Statistiques'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section effectifs ────────────────────────────────
            const _SectionTitle('Effectifs'),
            const SizedBox(height: 10),
            Row(children: [
              _StatTile(
                  label: 'Élèves inscrits',
                  value: '${students.length}',
                  icon: Icons.people_alt_outlined,
                  color: primaryBlue),
              const SizedBox(width: 12),
              _StatTile(
                  label: 'Classes',
                  value: '${classes.length}',
                  icon: Icons.class_outlined,
                  color: infoBlue),
            ]),

            const SizedBox(height: 20),
            const _SectionTitle('Présences'),
            const SizedBox(height: 10),
            Row(children: [
              _StatTile(
                  label: 'Total absences',
                  value: '${stats['total'] ?? 0}',
                  icon: Icons.event_busy_outlined,
                  color: dangerRed),
              const SizedBox(width: 12),
              _StatTile(
                  label: 'En attente',
                  value: '${stats['enAttente'] ?? 0}',
                  icon: Icons.pending_outlined,
                  color: warningYellow),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _StatTile(
                  label: 'Justifiées',
                  value: '${stats['justifiee'] ?? 0}',
                  icon: Icons.check_circle_outline,
                  color: successGreen),
              const SizedBox(width: 12),
              _StatTile(
                  label: 'Taux justif.',
                  value: '$tauxJustif%',
                  icon: Icons.percent,
                  color: successGreen),
            ]),

            // ── Barre taux justification ─────────────────────────
            if (totalAbs > 0) ...[
              const SizedBox(height: 16),
              _ProgressBar(
                label: 'Taux de justification',
                value: justified / totalAbs,
                color: successGreen,
              ),
            ],

            const SizedBox(height: 20),
            const _SectionTitle('Notes'),
            const SizedBox(height: 10),
            Row(children: [
              _StatTile(
                  label: 'Notes saisies',
                  value: '${grades.length}',
                  icon: Icons.grade_outlined,
                  color: infoBlue),
              const SizedBox(width: 12),
              _StatTile(
                  label: 'Moyenne globale',
                  value: avgGlobal.toStringAsFixed(2),
                  icon: Icons.calculate_outlined,
                  color: avgGlobal >= 10 ? successGreen : dangerRed),
            ]),

            // ── Barre moyenne globale ─────────────────────────────
            if (grades.isNotEmpty) ...[
              const SizedBox(height: 16),
              _ProgressBar(
                label: 'Moyenne sur 20',
                value: avgGlobal / 20,
                color: avgGlobal >= 10 ? successGreen : dangerRed,
              ),
            ],

            const SizedBox(height: 20),
            const _SectionTitle('Répartition par classe'),
            const SizedBox(height: 10),
            ...classes.map((c) {
              final count = students.where((s) => s.className == c.name).length;
              final ratio = c.capacity > 0 ? count / c.capacity : 0.0;
              return _ClassRow(
                className: c.name,
                count: count,
                capacity: c.capacity,
                ratio: ratio,
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Widgets locaux ─────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) => Text(
        title,
        style: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.bold, color: textDark),
      );
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: color)),
                  Text(label,
                      style: const TextStyle(fontSize: 11, color: textGrey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _ProgressBar({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, color: textGrey)),
            Text('${(value * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

class _ClassRow extends StatelessWidget {
  final String className;
  final int count;
  final int capacity;
  final double ratio;

  const _ClassRow({
    required this.className,
    required this.count,
    required this.capacity,
    required this.ratio,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(className,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio.clamp(0.0, 1.0),
                backgroundColor: primaryBlue.withValues(alpha: 0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(primaryBlue),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text('$count / $capacity',
              style: const TextStyle(color: textGrey, fontSize: 12)),
        ],
      ),
    );
  }
}
