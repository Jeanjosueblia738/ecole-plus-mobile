import 'package:flutter/material.dart';
import '../../../core/services/conseil_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../grades/data/grade_model.dart';

/// Carte read-only : mention et décision du conseil de classe.
class ConseilSummaryCard extends StatefulWidget {
  final bool isParent;
  final String? studentId;

  const ConseilSummaryCard({
    super.key,
    this.isParent = false,
    this.studentId,
  });

  @override
  State<ConseilSummaryCard> createState() => _ConseilSummaryCardState();
}

class _ConseilSummaryCardState extends State<ConseilSummaryCard> {
  List<dynamic> _decisions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = widget.isParent
          ? await ConseilApiService.getMyChild(studentId: widget.studentId)
          : await ConseilApiService.getMy();
      if (mounted) {
        setState(() {
          _decisions = data;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _mentionLabel(String? raw) {
    if (raw == null || raw == 'NIL') return '—';
    return raw
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .map((w) =>
            w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  String _decisionLabel(String? raw) => switch (raw) {
        'PASSAGE' => 'Passage en classe supérieure',
        'REDOUBLANT' => 'Redoublement',
        'EXCLUSION' => 'Exclusion',
        'ORIENTATION' => 'Orientation',
        _ => raw ?? '—',
      };

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 48,
        child: Center(
            child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }
    if (_decisions.isEmpty) return const SizedBox.shrink();

    final latest = _decisions.first;
    final trimestre = displayTrimestre(latest['trimestre']?.toString() ?? 'T1');
    final mention = _mentionLabel(latest['mention']?.toString());
    final decision = _decisionLabel(latest['decision']?.toString());
    final appreciation = latest['appreciation']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF7C3AED).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.gavel_outlined,
                  size: 18, color: Color(0xFF7C3AED)),
              SizedBox(width: 8),
              Text('Conseil de classe',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: textDark)),
            ],
          ),
          const SizedBox(height: 8),
          Text('$trimestre trimestre',
              style: const TextStyle(fontSize: 12, color: textGrey)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _MiniStat(label: 'Mention', value: mention),
              ),
              Expanded(
                child: _MiniStat(label: 'Décision', value: decision),
              ),
            ],
          ),
          if (appreciation != null && appreciation.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(appreciation,
                style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: textDark)),
          ],
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: textGrey)),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 12, color: textDark)),
      ],
    );
  }
}
