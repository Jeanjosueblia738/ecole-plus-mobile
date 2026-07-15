import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/teacher_provider.dart';
import '../../../core/providers/student_provider.dart';
import '../../../core/providers/attendance_provider.dart';
import '../../../core/providers/grade_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../grades/ui/grade_input_screen.dart';
import '../../grades/ui/grade_list_screen.dart';
import 'attendance_input_screen.dart';

class TeacherClassDetailScreen extends ConsumerWidget {
  final String className;
  final String? classId;

  const TeacherClassDetailScreen({
    super.key,
    required this.className,
    this.classId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final students = classId != null && classId!.isNotEmpty
        ? ref.watch(studentProvider.notifier).byClassId(classId!)
        : ref.watch(studentProvider.notifier).byClass(className);
    final absences = ref
        .watch(attendanceProvider)
        .where((a) => a.className == className)
        .toList();
    final grades = ref
        .watch(gradeProvider)
        .where((g) => g.className == className)
        .toList();
    final subjects = ref.watch(teacherSubjectsProvider);

    final avg = grades.isEmpty
        ? null
        : grades.fold(0.0, (s, g) => s + g.value) / grades.length;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          title: Text(className),
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(text: 'Élèves'),
              Tab(text: 'Absences'),
              Tab(text: 'Notes'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // ── Onglet Élèves ──────────────────────────────────
            _StudentsTab(
              students: students,
              onCallRoll: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AttendanceInputScreen(
                    className: className,
                    classId: classId,
                    subject: subjects.isNotEmpty ? subjects.first : 'Cours',
                    duration: '1h',
                  ),
                ),
              ),
            ),

            // ── Onglet Absences ────────────────────────────────
            _AbsencesTab(absences: absences),

            // ── Onglet Notes ───────────────────────────────────
            _GradesTab(
              className: className,
              subjects: subjects,
              grades: grades,
              moyenne: avg,
              students: students,
              onAddGrades: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GradeInputScreen(
                    className: className,
                    classId: classId,
                    trimestre: 'T1',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Onglet élèves ──────────────────────────────────────────────────────────
class _StudentsTab extends StatelessWidget {
  final List students;
  final VoidCallback onCallRoll;

  const _StudentsTab({required this.students, required this.onCallRoll});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Bouton faire l'appel
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.how_to_reg, color: Colors.white),
              label: const Text('Faire l\'appel maintenant',
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: dangerRed,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: onCallRoll,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '${students.length} élève${students.length > 1 ? 's' : ''}',
                style: const TextStyle(
                    color: textGrey, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: students.isEmpty
              ? const Center(
                  child: Text('Aucun élève', style: TextStyle(color: textGrey)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final s = students[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: primaryBlue.withValues(alpha: 0.1),
                        child: Text(
                          s.fullName[0].toUpperCase(),
                          style: const TextStyle(
                              color: primaryBlue, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(s.fullName),
                      subtitle: Text(s.parentPhone,
                          style: const TextStyle(fontSize: 12)),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ── Onglet absences ────────────────────────────────────────────────────────
class _AbsencesTab extends StatelessWidget {
  final List absences;
  const _AbsencesTab({required this.absences});

  @override
  Widget build(BuildContext context) {
    if (absences.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline,
                size: 56, color: Color(0xFF16A34A)),
            SizedBox(height: 10),
            Text('Aucune absence enregistrée',
                style: TextStyle(color: textGrey)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: absences.length,
      itemBuilder: (context, index) {
        final a = absences[index];
        final statusColor = switch (a.status) {
          'Justifiée' => successGreen,
          'En attente' => warningYellow,
          _ => dangerRed,
        };
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.studentName,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('${a.subject} • ${a.date}',
                        style: const TextStyle(color: textGrey, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(a.status,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Onglet notes ───────────────────────────────────────────────────────────
class _GradesTab extends StatelessWidget {
  final String className;
  final List<String> subjects;
  final List grades;
  final double? moyenne;
  final List students;
  final VoidCallback onAddGrades;

  const _GradesTab({
    required this.className,
    required this.subjects,
    required this.grades,
    required this.moyenne,
    required this.students,
    required this.onAddGrades,
  });

  @override
  Widget build(BuildContext context) {
    // Grouper par matière
    final Map<String, List> bySubject = {};
    for (final g in grades) {
      bySubject.putIfAbsent(g.subject, () => []).add(g);
    }

    return Column(
      children: [
        // Moyenne + bouton ajouter
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: moyenne == null
                        ? const Color(0xFFF3F4F6)
                        : (moyenne! >= 10 ? successGreen : dangerRed)
                            .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        moyenne != null ? moyenne!.toStringAsFixed(2) : '—',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: moyenne == null
                              ? textGrey
                              : moyenne! >= 10
                                  ? successGreen
                                  : dangerRed,
                        ),
                      ),
                      const Text('Moyenne de classe',
                          style: TextStyle(color: textGrey, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, color: Colors.white),
                label:
                    const Text('Saisir', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: infoBlue,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: onAddGrades,
              ),
            ],
          ),
        ),

        // Liste par matière
        Expanded(
          child: bySubject.isEmpty
              ? const Center(
                  child: Text('Aucune note saisie',
                      style: TextStyle(color: textGrey)))
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: bySubject.entries.map((e) {
                    final subGrades = e.value;
                    final subAvg = subGrades.fold(0.0, (s, g) => s + g.value) /
                        subGrades.length;
                    final isGood = subAvg >= 10;
                    return ListTile(
                      leading: Icon(Icons.book_outlined,
                          color: isGood ? successGreen : dangerRed),
                      title: Text(e.key),
                      subtitle: Text(
                          '${subGrades.length} note${subGrades.length > 1 ? 's' : ''}'),
                      trailing: Text(
                        subAvg.toStringAsFixed(2),
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isGood ? successGreen : dangerRed),
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GradeListScreen(
                            studentId:
                                students.isNotEmpty ? students.first.id : '',
                            studentName: className,
                            trimestre: '1er',
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}
