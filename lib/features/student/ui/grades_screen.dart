import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/grade_provider.dart';
import '../../../core/providers/student_provider.dart';
import '../../student/data/student.dart';
import '../../../core/theme/app_colors.dart';
import '../../grades/ui/grade_list_screen.dart';
import '../../grades/ui/bulletin_screen.dart';

class GradesScreen extends ConsumerStatefulWidget {
  final String studentId;
  final String studentName;

  const GradesScreen({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  ConsumerState<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends ConsumerState<GradesScreen> {
  String _trimestre = '1er';
  static const _trimestres = ['1er', '2ème', '3ème'];

  @override
  Widget build(BuildContext context) {
    final grades = ref.watch(gradesByStudentProvider(
        (studentId: widget.studentId, trimestre: _trimestre)));

    final allStudents = ref.watch(studentProvider);
    final myStudent =
        allStudents.where((s) => s.id == widget.studentId).toList();
    final classmates = myStudent.isEmpty
        ? <Student>[]
        : allStudents
            .where((s) => s.className == myStudent.first.className)
            .toList();

    final bulletin = myStudent.isEmpty
        ? null
        : ref.watch(bulletinProvider((
            studentId: widget.studentId,
            trimestre: _trimestre,
            classmates: classmates,
          )));

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(widget.studentName),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Sélecteur trimestre ────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _trimestres.map((t) {
                final selected = _trimestre == t;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: ChoiceChip(
                    label: Text('$t trim.'),
                    selected: selected,
                    selectedColor: primaryBlue.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      color: selected ? primaryBlue : textGrey,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) => setState(() => _trimestre = t),
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Carte moyenne générale ─────────────────────────────
          if (bulletin != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _MoyenneCard(
                moyenne: bulletin.moyenneGenerale,
                rang: bulletin.rang,
                total: bulletin.totalEleves,
                mention: bulletin.mention,
              ),
            ),

          // ── Boutons actions ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.list_alt),
                    label: const Text('Notes détaillées'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GradeListScreen(
                          studentId: widget.studentId,
                          studentName: widget.studentName,
                          trimestre: _trimestre,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                    label: const Text('Bulletin PDF',
                        style: TextStyle(color: Colors.white)),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: primaryBlue),
                    onPressed: bulletin == null
                        ? null
                        : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BulletinScreen(
                                  studentId: widget.studentId,
                                  trimestre: _trimestre,
                                ),
                              ),
                            ),
                  ),
                ),
              ],
            ),
          ),

          // ── Résumé rapide par matière ──────────────────────────
          Expanded(
            child: grades.isEmpty
                ? const Center(
                    child: Text('Aucune note ce trimestre',
                        style: TextStyle(color: textGrey)))
                : _SubjectSummaryList(grades: grades),
          ),
        ],
      ),
    );
  }
}

// ── Carte moyenne ──────────────────────────────────────────────────────────
class _MoyenneCard extends StatelessWidget {
  final double moyenne;
  final int rang;
  final int total;
  final String mention;

  const _MoyenneCard({
    required this.moyenne,
    required this.rang,
    required this.total,
    required this.mention,
  });

  @override
  Widget build(BuildContext context) {
    final isGood = moyenne >= 10;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isGood
            ? successGreen.withValues(alpha: 0.08)
            : dangerRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isGood
              ? successGreen.withValues(alpha: 0.3)
              : dangerRed.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                '${moyenne.toStringAsFixed(2)}/20',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isGood ? successGreen : dangerRed),
              ),
              const Text('Moyenne générale',
                  style: TextStyle(color: textGrey, fontSize: 11)),
            ],
          ),
          Column(
            children: [
              Text('$rang/$total',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textDark)),
              const Text('Rang',
                  style: TextStyle(color: textGrey, fontSize: 11)),
            ],
          ),
          Column(
            children: [
              Text(mention,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isGood ? successGreen : dangerRed)),
              const Text('Mention',
                  style: TextStyle(color: textGrey, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Résumé rapide matières ─────────────────────────────────────────────────
class _SubjectSummaryList extends StatelessWidget {
  final List grades;
  const _SubjectSummaryList({required this.grades});

  @override
  Widget build(BuildContext context) {
    final Map<String, List<double>> bySubject = {};
    for (final g in grades) {
      bySubject.putIfAbsent(g.subject, () => []).add(g.value);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: bySubject.entries.map((e) {
        final avg = e.value.fold(0.0, (s, v) => s + v) / e.value.length;
        final isGood = avg >= 10;
        return ListTile(
          title: Text(e.key),
          subtitle:
              Text('${e.value.length} note${e.value.length > 1 ? 's' : ''}'),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isGood
                  ? successGreen.withValues(alpha: 0.1)
                  : dangerRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              avg.toStringAsFixed(2),
              style: TextStyle(
                  color: isGood ? successGreen : dangerRed,
                  fontWeight: FontWeight.bold),
            ),
          ),
        );
      }).toList(),
    );
  }
}
