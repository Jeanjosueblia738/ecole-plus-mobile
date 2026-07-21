import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/grade_provider.dart';
import '../../../core/providers/student_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/school_year.dart';
import '../../../services/bulletin_pdf_service.dart';
import '../../student/data/student.dart';
import '../data/grade_model.dart';

class BulletinScreen extends ConsumerStatefulWidget {
  final String studentId;
  final String trimestre;

  const BulletinScreen({
    super.key,
    required this.studentId,
    required this.trimestre,
  });

  @override
  ConsumerState<BulletinScreen> createState() => _BulletinScreenState();
}

class _BulletinScreenState extends ConsumerState<BulletinScreen> {
  bool _isGenerating = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    var all = ref.read(studentProvider);
    if (all.isEmpty) {
      await ref.read(studentProvider.notifier).load();
      all = ref.read(studentProvider);
    }
    final student = all.where((s) => s.id == widget.studentId).toList();
    final classmates = student.isEmpty
        ? <Student>[]
        : all.where((s) => s.className == student.first.className).toList();

    final me = student.isEmpty ? null : student.first;
    if (me?.classId != null && me!.classId!.isNotEmpty && classmates.isNotEmpty) {
      await ref.read(gradeProvider.notifier).loadForClass(
            me.classId!,
            widget.trimestre,
            classmates: classmates,
          );
    } else {
      await ref.read(gradeProvider.notifier).loadForStudent(
            widget.studentId,
            trimestre: widget.trimestre,
            studentName: me?.fullName ?? '',
            className: me?.className ?? '',
          );
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _printOrShare(Bulletin bulletin) async {
    setState(() => _isGenerating = true);
    final auth = ref.read(authProvider);
    final classmates = ref
        .read(studentProvider)
        .where((s) => s.className == bulletin.className)
        .toList();
    final averages = <double>[];
    for (final s in classmates) {
      final b = ref.read(bulletinProvider((
        studentId: s.id,
        trimestre: widget.trimestre,
        classmates: classmates,
      )));
      if (b != null && b.results.isNotEmpty) {
        averages.add(b.moyenneGenerale);
      }
    }
    final pdfBytes = await BulletinPdfService.generate(
      bulletin,
      options: BulletinPdfOptions(
        schoolName: auth.tenantName ?? 'ÉTABLISSEMENT',
        schoolCode: auth.tenantCode ?? '',
        schoolCity: '',
        year: currentSchoolYear(),
        classAverage: averages.isEmpty
            ? null
            : averages.reduce((a, b) => a + b) / averages.length,
        classMin: averages.isEmpty
            ? null
            : averages.reduce((a, b) => a < b ? a : b),
        classMax: averages.isEmpty
            ? null
            : averages.reduce((a, b) => a > b ? a : b),
      ),
    );
    setState(() => _isGenerating = false);
    if (!mounted) return;

    await Printing.layoutPdf(
      onLayout: (_) async => pdfBytes,
      name: 'Bulletin_${bulletin.studentName}_${bulletin.trimestre}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final allStudents = ref.watch(studentProvider);
    final student = allStudents.where((s) => s.id == widget.studentId).toList();

    final classmates = student.isEmpty
        ? <Student>[
            Student(
              id: widget.studentId,
              fullName: '',
              className: '',
              parentPhone: '',
            )
          ]
        : allStudents
            .where((s) => s.className == student.first.className)
            .toList();

    final bulletin = ref.watch(bulletinProvider((
      studentId: widget.studentId,
      trimestre: widget.trimestre,
      classmates: classmates,
    )));

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Bulletin de notes'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          if (bulletin != null)
            IconButton(
              icon: _isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.picture_as_pdf),
              tooltip: 'Générer PDF',
              onPressed: _isGenerating ? null : () => _printOrShare(bulletin),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : bulletin == null
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.assignment_outlined,
                          size: 56, color: Color(0xFF9CA3AF)),
                      SizedBox(height: 12),
                      Text('Aucune note disponible ce trimestre',
                          style: TextStyle(color: textGrey)),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _SummaryCard(bulletin: bulletin),
                      const SizedBox(height: 16),
                      ...bulletin.results.map((r) => _SubjectRow(result: r)),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          icon: _isGenerating
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.picture_as_pdf,
                                  color: Colors.white),
                          label: Text(
                            _isGenerating
                                ? 'Génération...'
                                : 'Télécharger PDF',
                            style: const TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _isGenerating
                              ? null
                              : () => _printOrShare(bulletin),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final Bulletin bulletin;
  const _SummaryCard({required this.bulletin});

  @override
  Widget build(BuildContext context) {
    final isGood = bulletin.moyenneGenerale >= 10;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Text(bulletin.studentName,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Text(
            '${bulletin.className} • ${bulletin.trimestre} Trimestre',
            style: const TextStyle(color: textGrey, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Stat(
                label: 'Moyenne',
                value: bulletin.moyenneGenerale.toStringAsFixed(2),
                color: isGood ? successGreen : dangerRed,
              ),
              _Stat(
                label: 'Rang',
                value: '${bulletin.rang}/${bulletin.totalEleves}',
                color: textDark,
              ),
              _Stat(
                label: 'Mention',
                value: bulletin.mention,
                color: isGood ? successGreen : dangerRed,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Stat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: textGrey)),
      ],
    );
  }
}

class _SubjectRow extends StatelessWidget {
  final SubjectResult result;
  const _SubjectRow({required this.result});

  @override
  Widget build(BuildContext context) {
    final isGood = result.moyenne >= 10;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.subject,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('Coef. ${result.coefficient}',
                    style: const TextStyle(color: textGrey, fontSize: 12)),
              ],
            ),
          ),
          Text(
            result.moyenne.toStringAsFixed(2),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isGood ? successGreen : dangerRed,
            ),
          ),
        ],
      ),
    );
  }
}
