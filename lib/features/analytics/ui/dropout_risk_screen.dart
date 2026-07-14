import 'package:flutter/material.dart';
import '../../../core/services/analytics_api_service.dart';
import '../../../core/services/classes_api_service.dart';
import '../../../core/theme/app_colors.dart';

typedef RiskLevel = String;

class DropoutRiskScreen extends StatefulWidget {
  const DropoutRiskScreen({super.key});

  @override
  State<DropoutRiskScreen> createState() => _DropoutRiskScreenState();
}

class _DropoutRiskScreenState extends State<DropoutRiskScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;
  Map<String, dynamic>? _selected;
  List<dynamic> _classes = [];
  String? _classId;
  String _minLevel = 'MEDIUM';

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final classes = await ClassesApiService.getAll()
          .catchError((_) => <dynamic>[]);
      if (mounted) setState(() => _classes = classes);
    } catch (_) {}
    await _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await AnalyticsApiService.getDropoutRisk(
        classId: _classId,
        minLevel: _minLevel.isEmpty ? null : _minLevel,
      );
      if (!mounted) return;
      setState(() {
        _data = data;
        _selected = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible de charger l\'analyse';
        _loading = false;
      });
    }
  }

  Color _levelColor(String? level) => switch (level) {
        'CRITICAL' => dangerRed,
        'HIGH' => const Color(0xFFEA580C),
        'MEDIUM' => warningYellow,
        'LOW' => successGreen,
        _ => textGrey,
      };

  String _levelLabel(String? level) => switch (level) {
        'CRITICAL' => 'Critique',
        'HIGH' => 'Élevé',
        'MEDIUM' => 'Modéré',
        'LOW' => 'Faible',
        _ => level ?? '—',
      };

  @override
  Widget build(BuildContext context) {
    final summary = _data?['summary'] as Map<String, dynamic>?;
    final students = (_data?['students'] as List<dynamic>?) ?? [];

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Risque décrochage'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.refresh_outlined),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: primaryBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryBlue.withValues(alpha: 0.2)),
              ),
              child: const Text(
                'MVP analytique — score pondéré (absences, notes, tendance, impayés). '
                'Pas un réseau de neurones ; un modèle ML pourra remplacer le moteur plus tard.',
                style: TextStyle(fontSize: 12, color: primaryBlue, height: 1.35),
              ),
            ),
            const SizedBox(height: 14),

            if (summary != null) ...[
              Row(children: [
                _SummaryChip('Analysés', summary['total'], textDark),
                const SizedBox(width: 8),
                _SummaryChip('Critiques', summary['critical'], dangerRed),
                const SizedBox(width: 8),
                _SummaryChip(
                    'Élevés', summary['high'], const Color(0xFFEA580C)),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                _SummaryChip('Modérés', summary['medium'], warningYellow),
                const SizedBox(width: 8),
                _SummaryChip('Faibles', summary['low'], successGreen),
                const SizedBox(width: 8),
                const Expanded(child: SizedBox()),
              ]),
              const SizedBox(height: 14),
            ],

            Row(children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue: _classId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Classe',
                    border: OutlineInputBorder(),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                        value: null, child: Text('Toutes')),
                    ..._classes.map((c) {
                      final m = c as Map<String, dynamic>;
                      return DropdownMenuItem<String?>(
                        value: m['id'] as String?,
                        child: Text(m['name'] as String? ?? 'Classe',
                            overflow: TextOverflow.ellipsis),
                      );
                    }),
                  ],
                  onChanged: (v) {
                    setState(() => _classId = v);
                    _load();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _minLevel,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Seuil min.',
                    border: OutlineInputBorder(),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: const [
                    DropdownMenuItem(value: '', child: Text('Tous')),
                    DropdownMenuItem(value: 'MEDIUM', child: Text('Modéré+')),
                    DropdownMenuItem(value: 'HIGH', child: Text('Élevé+')),
                    DropdownMenuItem(
                        value: 'CRITICAL', child: Text('Critique')),
                  ],
                  onChanged: (v) {
                    setState(() => _minLevel = v ?? 'MEDIUM');
                    _load();
                  },
                ),
              ),
            ]),
            const SizedBox(height: 16),

            if (_error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: dangerRed.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: dangerRed.withValues(alpha: 0.3)),
                ),
                child: Text(_error!,
                    style: const TextStyle(color: dangerRed, fontSize: 13)),
              ),

            Text(
              'Élèves à risque (${students.length})',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15, color: textDark),
            ),
            const SizedBox(height: 10),

            if (_loading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (students.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: border),
                ),
                child: const Center(
                  child: Text('Aucun élève au-dessus du seuil.',
                      style: TextStyle(color: textGrey)),
                ),
              )
            else
              ...students.map((raw) {
                final s = raw as Map<String, dynamic>;
                final level = s['riskLevel'] as String?;
                final color = _levelColor(level);
                final isSelected = _selected?['studentId'] == s['studentId'];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => setState(() => _selected = s),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primaryBlue.withValues(alpha: 0.06)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? primaryBlue.withValues(alpha: 0.35)
                              : border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${s['lastName'] ?? ''} ${s['firstName'] ?? ''}'
                                      .trim(),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                ),
                                Text(
                                  '${s['className'] ?? 'Sans classe'} · ${s['registrationNo'] ?? ''}',
                                  style: const TextStyle(
                                      color: textGrey, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${s['score'] ?? '—'}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: color.withValues(alpha: 0.35)),
                            ),
                            child: Text(
                              _levelLabel(level),
                              style: TextStyle(
                                  color: color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

            if (_selected != null) ...[
              const SizedBox(height: 16),
              _DetailPanel(
                student: _selected!,
                levelColor: _levelColor(_selected!['riskLevel'] as String?),
                levelLabel: _levelLabel(_selected!['riskLevel'] as String?),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final dynamic value;
  final Color color;
  const _SummaryChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text('${value ?? 0}',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(label,
                style: const TextStyle(fontSize: 10, color: textGrey),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _DetailPanel extends StatelessWidget {
  final Map<String, dynamic> student;
  final Color levelColor;
  final String levelLabel;
  const _DetailPanel({
    required this.student,
    required this.levelColor,
    required this.levelLabel,
  });

  @override
  Widget build(BuildContext context) {
    final factors = (student['factors'] as List<dynamic>?) ?? [];
    final recommendations =
        (student['recommendations'] as List<dynamic>?) ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${student['lastName'] ?? ''} ${student['firstName'] ?? ''}'
                          .trim(),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(student['className'] as String? ?? '',
                        style:
                            const TextStyle(color: textGrey, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: levelColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: levelColor.withValues(alpha: 0.35)),
                ),
                child: Text(
                  '$levelLabel · ${student['score'] ?? '—'}/100',
                  style: TextStyle(
                      color: levelColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Facteurs',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13, color: textGrey)),
          const SizedBox(height: 10),
          ...factors.map((raw) {
            final f = raw as Map<String, dynamic>;
            final score = (f['score'] as num?)?.toDouble() ?? 0;
            final barColor = score >= 60
                ? dangerRed
                : score >= 35
                    ? warningYellow
                    : successGreen;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(f['label'] as String? ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                      Text(
                        '${f['score'] ?? 0}/100 · poids ${f['weight'] ?? ''}',
                        style:
                            const TextStyle(color: textGrey, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (score / 100).clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade100,
                      color: barColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(f['detail'] as String? ?? '',
                      style:
                          const TextStyle(color: textGrey, fontSize: 11)),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          const Text('Recommandations',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13, color: textGrey)),
          const SizedBox(height: 8),
          ...recommendations.map((r) => Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: warningYellow.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: warningYellow.withValues(alpha: 0.3)),
                ),
                child: Text('$r',
                    style: const TextStyle(fontSize: 13, height: 1.35)),
              )),
        ],
      ),
    );
  }
}
