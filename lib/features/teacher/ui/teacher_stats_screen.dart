import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/teacher_provider.dart';
import '../../../core/theme/app_colors.dart';

class TeacherStatsScreen extends ConsumerWidget {
  const TeacherStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(teacherProfileProvider);
    final classStats = ref.watch(teacherClassStatsProvider);
    final myGrades = ref.watch(teacherGradesProvider);

    final totalNotes = myGrades.length;
    final globalAvg = myGrades.isEmpty
        ? null
        : myGrades.fold(0.0, (s, g) => s + g.value) / myGrades.length;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Mes statistiques'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Résumé global ──────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: primaryBlue,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    profile.fullName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    profile.subjects.join(' • '),
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _GlobalStat(
                          label: 'Classes', value: '${classStats.length}'),
                      _GlobalStat(label: 'Notes saisies', value: '$totalNotes'),
                      _GlobalStat(
                          label: 'Moy. globale',
                          value: globalAvg != null
                              ? globalAvg.toStringAsFixed(1)
                              : '—'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text('Par classe',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textDark)),
            const SizedBox(height: 12),

            // ── Stats par classe ───────────────────────────────────
            ...classStats.map((cs) {
              final avg = cs.moyenneClasse;
              final isGood = avg != null && avg >= 10;
              final ratio = avg != null ? avg / 20 : 0.0;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(cs.className,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                        Text(
                          avg != null
                              ? '${avg.toStringAsFixed(1)}/20'
                              : 'Aucune note',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: avg == null
                                ? textGrey
                                : isGood
                                    ? successGreen
                                    : dangerRed,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${cs.studentCount} élève${cs.studentCount > 1 ? 's' : ''} • '
                      '${cs.absenceCount} absence${cs.absenceCount > 1 ? 's' : ''}',
                      style: const TextStyle(color: textGrey, fontSize: 12),
                    ),
                    if (avg != null) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ratio.clamp(0.0, 1.0),
                          backgroundColor: (isGood ? successGreen : dangerRed)
                              .withValues(alpha: 0.12),
                          valueColor: AlwaysStoppedAnimation<Color>(
                              isGood ? successGreen : dangerRed),
                          minHeight: 7,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _GlobalStat extends StatelessWidget {
  final String label;
  final String value;

  const _GlobalStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}
