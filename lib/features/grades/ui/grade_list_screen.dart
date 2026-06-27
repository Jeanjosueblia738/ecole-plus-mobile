import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/grade_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../data/grade_model.dart';

class GradeListScreen extends ConsumerWidget {
  final String studentId;
  final String studentName;
  final String trimestre;

  const GradeListScreen({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.trimestre,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grades = ref.watch(
        gradesByStudentProvider((studentId: studentId, trimestre: trimestre)));

    // Grouper par matière
    final Map<String, List<Grade>> bySubject = {};
    for (final g in grades) {
      bySubject.putIfAbsent(g.subject, () => []).add(g);
    }

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(studentName),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: grades.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.assignment_outlined,
                      size: 56, color: Color(0xFF9CA3AF)),
                  SizedBox(height: 12),
                  Text('Aucune note ce trimestre',
                      style: TextStyle(color: textGrey)),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: bySubject.entries.map((entry) {
                final subject = entry.key;
                final subGrades = entry.value;
                final avg = subGrades.fold(0.0, (s, g) => s + g.value) /
                    subGrades.length;
                return _SubjectCard(
                  subject: subject,
                  coefficient: subGrades.first.coefficient,
                  grades: subGrades,
                  moyenne: avg,
                );
              }).toList(),
            ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final String subject;
  final int coefficient;
  final List<Grade> grades;
  final double moyenne;

  const _SubjectCard({
    required this.subject,
    required this.coefficient,
    required this.grades,
    required this.moyenne,
  });

  Color get _moyenneColor => moyenne >= 10
      ? successGreen
      : moyenne >= 8
          ? warningYellow
          : dangerRed;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          // ── En-tête matière ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(subject,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      Text('Coef. $coefficient',
                          style:
                              const TextStyle(color: textGrey, fontSize: 12)),
                    ],
                  ),
                ),
                // Moyenne matière
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: _moyenneColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    moyenne.toStringAsFixed(2),
                    style: TextStyle(
                      color: _moyenneColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // ── Notes détaillées ────────────────────────────────────
          ...grades.map((g) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    _EvalBadge(type: g.evalType),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(g.date,
                            style: const TextStyle(
                                color: textGrey, fontSize: 13))),
                    Text(
                      '${g.value.toStringAsFixed(2)} / 20',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: g.value >= 10 ? textDark : dangerRed,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _EvalBadge extends StatelessWidget {
  final EvalType type;
  const _EvalBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final color = switch (type) {
      EvalType.examen => const Color(0xFF7C3AED),
      EvalType.devoir => const Color(0xFF2563EB),
      EvalType.controle => const Color(0xFF059669),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(type.label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
