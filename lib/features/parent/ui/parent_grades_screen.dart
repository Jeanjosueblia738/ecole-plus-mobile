import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../../core/providers/parent_provider.dart';
import '../../../core/providers/grade_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/bulletin_pdf_service.dart';
import '../../grades/data/grade_model.dart';

class ParentGradesScreen extends ConsumerStatefulWidget {
  const ParentGradesScreen({super.key});

  @override
  ConsumerState<ParentGradesScreen> createState() => _ParentGradesScreenState();
}

class _ParentGradesScreenState extends ConsumerState<ParentGradesScreen> {
  String _trimestre = '1er';
  static const _trimestres = ['1er', '2ème', '3ème'];
  bool _isGenerating = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(parentChildAsyncProvider.future);
      final child = ref.read(parentChildProvider);
      if (child == null) {
        setState(() {
          _loading = false;
          _error = 'Aucun enfant lié';
        });
        return;
      }
      await ref.read(gradeProvider.notifier).loadForStudent(
            child.id,
            trimestre: _trimestre,
            studentName: child.fullName,
            className: child.className,
          );
      final gradeErr = ref.read(gradeProvider.notifier).error;
      if (gradeErr != null) _error = gradeErr;
    } catch (_) {
      _error = 'Impossible de charger les notes';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _onTrimestreChanged(String t) async {
    setState(() => _trimestre = t);
    final child = ref.read(parentChildProvider);
    if (child == null) return;
    setState(() => _loading = true);
    await ref.read(gradeProvider.notifier).loadForStudent(
          child.id,
          trimestre: t,
          studentName: child.fullName,
          className: child.className,
        );
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _downloadBulletin(Bulletin bulletin) async {
    setState(() => _isGenerating = true);
    final bytes = await BulletinPdfService.generate(bulletin);
    setState(() => _isGenerating = false);
    if (!mounted) return;
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'Bulletin_${bulletin.studentName}_${bulletin.trimestre}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final child = ref.watch(parentChildProvider);
    final grades = ref.watch(parentChildGradesProvider(_trimestre));
    final moyenne = ref.watch(parentChildAverageProvider(_trimestre));

    final bulletin = child == null
        ? null
        : ref.watch(bulletinProvider((
            studentId: child.id,
            trimestre: _trimestre,
            classmates: [child],
          )));

    final Map<String, List<Grade>> bySubject = {};
    for (final g in grades) {
      bySubject.putIfAbsent(g.subject, () => []).add(g);
    }

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Notes & Bulletin'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
          if (bulletin != null)
            IconButton(
              icon: _isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.picture_as_pdf),
              tooltip: 'Télécharger bulletin PDF',
              onPressed:
                  _isGenerating ? null : () => _downloadBulletin(bulletin),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: const TextStyle(color: textGrey)),
                      const SizedBox(height: 12),
                      TextButton(onPressed: _load, child: const Text('Réessayer')),
                    ],
                  ),
                )
              : Column(
                  children: [
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
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              onSelected: (_) => _onTrimestreChanged(t),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    if (moyenne != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _MoyenneBanner(
                            moyenne: moyenne,
                            rang: bulletin?.rang,
                            total: bulletin?.totalEleves,
                            mention: bulletin?.mention),
                      ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _buildGradesBody(grades, bySubject),
                    ),
                    if (bulletin != null)
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              icon: _isGenerating
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.download,
                                      color: Colors.white),
                              label: Text(
                                _isGenerating
                                    ? 'Génération...'
                                    : 'Télécharger le bulletin PDF',
                                style: const TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryBlue,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12))),
                              onPressed: _isGenerating
                                  ? null
                                  : () => _downloadBulletin(bulletin),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }

  Widget _buildGradesBody(
    List<Grade> grades,
    Map<String, List<Grade>> bySubject,
  ) {
    final gradeErr = ref.read(gradeProvider.notifier).error;
    if (gradeErr != null && grades.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(gradeErr, style: const TextStyle(color: textGrey)),
            const SizedBox(height: 12),
            TextButton(onPressed: _load, child: const Text('Réessayer')),
          ],
        ),
      );
    }
    if (grades.isEmpty) {
      return const Center(
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
      );
    }
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: bySubject.entries.map((e) {
        final subGrades = e.value;
        final avg =
            subGrades.fold(0.0, (s, g) => s + g.value) / subGrades.length;
        return _SubjectCard(
          subject: e.key,
          coef: subGrades.first.coefficient,
          grades: subGrades,
          moyenne: avg,
        );
      }).toList(),
    );
  }
}

class _MoyenneBanner extends StatelessWidget {
  final double moyenne;
  final int? rang;
  final int? total;
  final String? mention;

  const _MoyenneBanner({
    required this.moyenne,
    this.rang,
    this.total,
    this.mention,
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
          _BannerStat(
            label: 'Moyenne',
            value: '${moyenne.toStringAsFixed(2)}/20',
            color: isGood ? successGreen : dangerRed,
          ),
          if (rang != null && total != null)
            _BannerStat(
              label: 'Rang',
              value: '$rang/$total',
              color: textDark,
            ),
          if (mention != null)
            _BannerStat(
              label: 'Mention',
              value: mention!,
              color: isGood ? successGreen : dangerRed,
            ),
        ],
      ),
    );
  }
}

class _BannerStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _BannerStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 15, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: textGrey)),
      ],
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final String subject;
  final int coef;
  final List<Grade> grades;
  final double moyenne;

  const _SubjectCard({
    required this.subject,
    required this.coef,
    required this.grades,
    required this.moyenne,
  });

  @override
  Widget build(BuildContext context) {
    final isGood = moyenne >= 10;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        title: Text(subject,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text('Coef. $coef',
            style: const TextStyle(color: textGrey, fontSize: 12)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: isGood
                ? successGreen.withValues(alpha: 0.12)
                : dangerRed.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            moyenne.toStringAsFixed(2),
            style: TextStyle(
                color: isGood ? successGreen : dangerRed,
                fontWeight: FontWeight.bold,
                fontSize: 14),
          ),
        ),
        children: grades.map((g) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(
              children: [
                _EvalChip(type: g.evalType),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(g.date,
                        style: const TextStyle(color: textGrey, fontSize: 13))),
                Text(
                  '${g.value.toStringAsFixed(1)}/20',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: g.value >= 10 ? textDark : dangerRed),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _EvalChip extends StatelessWidget {
  final EvalType type;
  const _EvalChip({required this.type});

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
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
