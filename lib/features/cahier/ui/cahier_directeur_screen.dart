import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/cahier_api_service.dart';
import '../../../core/services/teacher_api_service.dart';

class CahierDirecteurScreen extends ConsumerStatefulWidget {
  const CahierDirecteurScreen({super.key});

  @override
  ConsumerState<CahierDirecteurScreen> createState() =>
      _CahierDirecteurScreenState();
}

class _CahierDirecteurScreenState extends ConsumerState<CahierDirecteurScreen> {
  List<dynamic> _classes = [];
  String? _selectedClassId;
  String _selectedClassName = '';
  String _trimestre = 'T1';
  List<dynamic> _entries = [];
  Map<String, dynamic>? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), _loadData);
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Charger stats + classes en parallèle
      final results = await Future.wait([
        CahierApiService.getStats().catchError((_) => <String, dynamic>{}),
        TeacherApiService.getMyClasses().catchError((_) => <dynamic>[]),
      ]);

      if (!mounted) return;
      final stats = results[0] as Map<String, dynamic>;
      final classes = results[1] as List<dynamic>;

      if (classes.isEmpty && stats.isEmpty) {
        setState(() {
          _loading = false;
          _error =
              'Impossible de charger le cahier. Vérifiez votre connexion.';
        });
        return;
      }

      setState(() {
        _stats = stats;
        _classes = classes;
        if (classes.isNotEmpty && _selectedClassId == null) {
          _selectedClassId = classes[0]['id'] as String;
          _selectedClassName = classes[0]['name'] as String;
        }
      });
      await _loadEntries();
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error =
              'Impossible de charger le cahier. Vérifiez votre connexion.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur de chargement du cahier de texte'),
            backgroundColor: dangerRed,
          ),
        );
      }
    }
  }

  Future<void> _loadEntries() async {
    if (_selectedClassId == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final entries = await CahierApiService.getByClass(_selectedClassId!,
              trimestre: _trimestre)
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error =
              'Impossible de charger les séances. Tirez pour actualiser.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur de chargement des séances'),
            backgroundColor: dangerRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final emarge = _entries.where((e) => e['isEmarge'] == true).length;
    final nonEmarge = _entries.length - emarge;
    final tauxEmargement =
        _entries.isEmpty ? 0 : (emarge / _entries.length * 100).round();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text('Cahier de texte',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          if (_loading)
            const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))),
          IconButton(
              icon: const Icon(Icons.refresh_outlined, size: 20),
              onPressed: _loadData),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (_error != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!,
                          style: TextStyle(
                              color: Colors.red.shade800, fontSize: 13)),
                    ),
                    TextButton(
                        onPressed: _loadData, child: const Text('Réessayer')),
                  ],
                ),
              ),
            // ── Stats globales ─────────────────────────────────────────
            Row(children: [
              _StatCard(
                  label: 'Total séances',
                  value: (_stats?['total'] ?? 0).toString(),
                  color: primaryBlue),
              const SizedBox(width: 10),
              _StatCard(
                  label: 'Avec travail à rendre',
                  value: (_stats?['avecDevoirs'] ?? 0).toString(),
                  color: warningYellow),
              const SizedBox(width: 10),
              _StatCard(
                  label: 'Taux émargement',
                  value: '$tauxEmargement%',
                  color: tauxEmargement >= 80 ? successGreen : dangerRed),
            ]),

            const SizedBox(height: 14),

            // ── Filtres ────────────────────────────────────────────────
            Row(children: [
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedClassId,
                    isExpanded: true,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                    style:
                        const TextStyle(fontSize: 13, color: Color(0xFF1F2937)),
                    onChanged: (val) {
                      if (val == null) return;
                      final cls = _classes.firstWhere((c) => c['id'] == val);
                      setState(() {
                        _selectedClassId = val;
                        _selectedClassName = cls['name'] as String;
                      });
                      _loadEntries();
                    },
                    items: _classes
                        .map<DropdownMenuItem<String>>((c) => DropdownMenuItem(
                            value: c['id'] as String,
                            child: Text(c['name'] as String)))
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: DropdownButton<String>(
                  value: _trimestre,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF1F2937)),
                  onChanged: (val) {
                    if (val == null) return;
                    setState(() => _trimestre = val);
                    _loadEntries();
                  },
                  items: const [
                    DropdownMenuItem(value: 'T1', child: Text('T1')),
                    DropdownMenuItem(value: 'T2', child: Text('T2')),
                    DropdownMenuItem(value: 'T3', child: Text('T3')),
                  ],
                ),
              ),
            ]),

            const SizedBox(height: 8),

            // Résumé classe
            if (_entries.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: nonEmarge > 0
                      ? dangerRed.withValues(alpha: 0.05)
                      : successGreen.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: nonEmarge > 0
                          ? dangerRed.withValues(alpha: 0.2)
                          : successGreen.withValues(alpha: 0.2)),
                ),
                child: Row(children: [
                  Icon(
                      nonEmarge > 0
                          ? Icons.warning_amber_outlined
                          : Icons.check_circle_outline,
                      color: nonEmarge > 0 ? dangerRed : successGreen,
                      size: 18),
                  const SizedBox(width: 8),
                  Text(
                    nonEmarge > 0
                        ? '$nonEmarge séance(s) non émargée(s) sur ${_entries.length}'
                        : 'Toutes les séances sont émargées ✓',
                    style: TextStyle(
                        fontSize: 12,
                        color: nonEmarge > 0 ? dangerRed : successGreen,
                        fontWeight: FontWeight.w600),
                  ),
                ]),
              ),

            const SizedBox(height: 12),

            // ── Tableau cahier de texte ────────────────────────────────
            const Text('Registre pédagogique',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textDark)),
            const SizedBox(height: 8),

            if (_loading)
              const Center(
                  child: Padding(
                      padding: EdgeInsets.all(30),
                      child: CircularProgressIndicator()))
            else if (_entries.isEmpty)
              Center(
                  child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(children: [
                  Icon(Icons.book_outlined,
                      size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 10),
                  Text('Aucune entrée pour $_selectedClassName — $_trimestre',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade500)),
                ]),
              ))
            else
              ...(_entries.map((entry) => _DirecteurEntryCard(entry: entry))),

            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }
}

// ── Carte entrée (vue directeur — lecture seule) ───────────────────────────
class _DirecteurEntryCard extends StatelessWidget {
  final Map<String, dynamic> entry;
  const _DirecteurEntryCard({required this.entry});

  String _fmtDate(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    const mois = [
      'jan',
      'fév',
      'mar',
      'avr',
      'mai',
      'jun',
      'jul',
      'aoû',
      'sep',
      'oct',
      'nov',
      'déc'
    ];
    return '${d.day.toString().padLeft(2, '0')} ${mois[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isEmarge = entry['isEmarge'] as bool? ?? false;
    final teacher = entry['teacher'] as Map<String, dynamic>?;
    final teacherName =
        teacher != null ? '${teacher['firstName']} ${teacher['lastName']}' : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isEmarge
                ? successGreen.withValues(alpha: 0.2)
                : Colors.grey.shade100),
      ),
      child: Column(children: [
        // En-tête
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isEmarge
                ? successGreen.withValues(alpha: 0.05)
                : Colors.grey.shade50,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(entry['subject'] ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  Row(children: [
                    const Icon(Icons.calendar_today, size: 11, color: textGrey),
                    const SizedBox(width: 4),
                    Text(_fmtDate(entry['date'] as String? ?? ''),
                        style: const TextStyle(fontSize: 11, color: textGrey)),
                    if (teacherName.isNotEmpty) ...[
                      const Text(' • ',
                          style: TextStyle(fontSize: 11, color: textGrey)),
                      Text(teacherName,
                          style:
                              const TextStyle(fontSize: 11, color: textGrey)),
                    ],
                  ]),
                ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isEmarge
                    ? successGreen.withValues(alpha: 0.1)
                    : dangerRed.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                    isEmarge
                        ? Icons.check_circle_outline
                        : Icons.pending_outlined,
                    size: 13,
                    color: isEmarge ? successGreen : dangerRed),
                const SizedBox(width: 4),
                Text(isEmarge ? 'Émargé' : 'Non émargé',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isEmarge ? successGreen : dangerRed)),
              ]),
            ),
          ]),
        ),

        // Contenu
        Padding(
          padding: const EdgeInsets.all(14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _InfoRow(
                label: 'Plan du cours',
                value: entry['planCours'] as String? ?? ''),
            if (entry['prochainCours'] != null) ...[
              const SizedBox(height: 8),
              _InfoRow(
                  label: 'Prochain cours',
                  value: entry['prochainCours'] as String),
            ],
            if (entry['devoirDescription'] != null) ...[
              const SizedBox(height: 8),
              _InfoRow(
                  label: 'Travail à rendre',
                  value: entry['devoirDescription'] as String,
                  color: const Color(0xFF92400E)),
            ],
          ]),
        ),
      ]),
    );
  }
}

// ── Widgets utilitaires ────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatCard(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(children: [
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label,
              style: const TextStyle(fontSize: 10, color: textGrey),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  final Color? color;
  const _InfoRow({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color ?? primaryBlue,
              letterSpacing: 0.5)),
      const SizedBox(height: 2),
      Text(value,
          style: const TextStyle(fontSize: 13, color: Color(0xFF374151))),
    ]);
  }
}

