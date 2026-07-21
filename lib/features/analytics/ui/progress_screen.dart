import 'package:flutter/material.dart';
import '../../../core/services/analytics_api_service.dart';
import '../../../core/theme/app_colors.dart';

/// Progression scolaire par matière (élève ou parent).
class ProgressScreen extends StatefulWidget {
  final bool isParent;
  final String? studentId;

  const ProgressScreen({super.key, this.isParent = false, this.studentId});

  factory ProgressScreen.forStudent() =>
      const ProgressScreen(isParent: false);

  factory ProgressScreen.forParent({String? studentId}) =>
      ProgressScreen(isParent: true, studentId: studentId);

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = widget.isParent
          ? await AnalyticsApiService.getMyChildProgress(
              studentId: widget.studentId,
            )
          : await AnalyticsApiService.getMyProgress();
      if (mounted) {
        setState(() {
          _data = data;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Impossible de charger la progression';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final student = _data?['student'] as Map<String, dynamic>?;
    final overall = (_data?['overall'] as num?)?.toDouble();
    final bySubject = (_data?['bySubject'] as List<dynamic>?) ?? [];
    final alerts = (_data?['alerts'] as List<dynamic>?) ?? [];
    final trend = _data?['trend']?.toString() ?? 'unknown';
    final trendDelta = (_data?['trendDelta'] as num?)?.toDouble();

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Progression'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: const TextStyle(color: dangerRed)),
                      TextButton(onPressed: _load, child: const Text('Réessayer')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (student != null)
                        Text(
                          '${student['firstName'] ?? ''} ${student['lastName'] ?? ''}'
                              .trim(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                      if (student?['class'] != null)
                        Text(
                          student!['class']['name']?.toString() ?? '',
                          style: const TextStyle(color: textGrey, fontSize: 13),
                        ),
                      const SizedBox(height: 16),
                      if (overall != null)
                        _OverallCard(
                          moyenne: overall,
                          trend: trend,
                          trendDelta: trendDelta,
                        ),
                      if (alerts.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text('Alertes',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: textDark)),
                        const SizedBox(height: 8),
                        ...alerts.map((a) => _AlertTile(alert: a)),
                      ],
                      const SizedBox(height: 16),
                      const Text('Par matière',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: textDark)),
                      const SizedBox(height: 8),
                      if (bySubject.isEmpty)
                        const Text('Pas encore de notes enregistrées',
                            style: TextStyle(color: textGrey))
                      else
                        ...bySubject.map((s) => _SubjectBar(subject: s)),
                    ],
                  ),
                ),
    );
  }
}

class _OverallCard extends StatelessWidget {
  final double moyenne;
  final String trend;
  final double? trendDelta;

  const _OverallCard({
    required this.moyenne,
    required this.trend,
    this.trendDelta,
  });

  IconData get _trendIcon => switch (trend) {
        'up' => Icons.trending_up,
        'down' => Icons.trending_down,
        'stable' => Icons.trending_flat,
        _ => Icons.help_outline,
      };

  Color get _trendColor => switch (trend) {
        'up' => successGreen,
        'down' => dangerRed,
        'stable' => infoBlue,
        _ => textGrey,
      };

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
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Moyenne générale',
                  style: TextStyle(fontSize: 12, color: textGrey)),
              Text(
                '${moyenne.toStringAsFixed(2)}/20',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isGood ? successGreen : dangerRed,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (trend != 'unknown')
            Column(
              children: [
                Icon(_trendIcon, color: _trendColor),
                if (trendDelta != null)
                  Text(
                    '${trendDelta! >= 0 ? '+' : ''}${trendDelta!.toStringAsFixed(1)}',
                    style: TextStyle(fontSize: 11, color: _trendColor),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final dynamic alert;
  const _AlertTile({required this.alert});

  @override
  Widget build(BuildContext context) {
    final severity = alert['severity']?.toString() ?? 'warning';
    final color = severity == 'danger' ? dangerRed : warningYellow;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_outlined, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              alert['message']?.toString() ?? '',
              style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.9)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectBar extends StatelessWidget {
  final dynamic subject;
  const _SubjectBar({required this.subject});

  @override
  Widget build(BuildContext context) {
    final name = subject['subject']?.toString() ?? '';
    final overall = (subject['overall'] as num?)?.toDouble();
    final count = (subject['count'] as num?)?.toInt() ?? 0;
    if (overall == null) return const SizedBox.shrink();

    final pct = (overall / 20).clamp(0.0, 1.0);
    final isGood = overall >= 10;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
              ),
              Text(
                '${overall.toStringAsFixed(1)}/20',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isGood ? successGreen : dangerRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              color: isGood ? successGreen : dangerRed,
            ),
          ),
          const SizedBox(height: 4),
          Text('$count note(s)',
              style: const TextStyle(fontSize: 10, color: textGrey)),
        ],
      ),
    );
  }
}
