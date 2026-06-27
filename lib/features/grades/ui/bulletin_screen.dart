import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../../core/providers/grade_provider.dart';
import '../../../core/providers/student_provider.dart';
import '../../student/data/student.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/bulletin_pdf_service.dart';
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

  Future<void> _printOrShare(Bulletin bulletin) async {
    setState(() => _isGenerating = true);
    final pdfBytes = await BulletinPdfService.generate(bulletin);
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

    // Élèves de la même classe pour le calcul du rang
    final classmates = student.isEmpty
        ? <Student>[]
        : allStudents
            .where((s) => s.className == student.first.className)
            .toList();

    final bulletin = student.isEmpty
        ? null
        : ref.watch(bulletinProvider((
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
      body: bulletin == null
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
                  // ── Carte résumé élève ──────────────────────────
                  _SummaryCard(bulletin: bulletin),
                  const SizedBox(height: 16),

                  // ── Tableau des matières ────────────────────────
                  ...bulletin.results.map((r) => _SubjectRow(result: r)),
                  const SizedBox(height: 16),

                  // ── Bouton PDF ──────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 50,
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
                            : 'Télécharger le bulletin PDF',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed:
                          _isGenerating ? null : () => _printOrShare(bulletin),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ── Carte résumé ───────────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final Bulletin bulletin;
  const _SummaryCard({required this.bulletin});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            bulletin.studentName,
            style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            '${bulletin.className} • ${bulletin.trimestre} Trimestre',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                  label: 'Moyenne',
                  value: '${bulletin.moyenneGenerale.toStringAsFixed(2)}/20',
                  color: bulletin.estAdmis
                      ? const Color(0xFF86EFAC)
                      : const Color(0xFFFCA5A5)),
              _StatItem(
                  label: 'Rang',
                  value: '${bulletin.rang}e / ${bulletin.totalEleves}',
                  color: Colors.white),
              _StatItem(
                  label: 'Mention',
                  value: bulletin.mention,
                  color: bulletin.estAdmis
                      ? const Color(0xFF86EFAC)
                      : const Color(0xFFFCA5A5)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatItem(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 11)),
      ],
    );
  }
}

// ── Ligne matière ──────────────────────────────────────────────────────────
class _SubjectRow extends StatelessWidget {
  final SubjectResult result;
  const _SubjectRow({required this.result});

  Color get _color => result.moyenne >= 10 ? successGreen : dangerRed;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                Text('Coef. ${result.coefficient}',
                    style: const TextStyle(color: textGrey, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              result.moyenne.toStringAsFixed(2),
              style: TextStyle(
                  color: _color, fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
