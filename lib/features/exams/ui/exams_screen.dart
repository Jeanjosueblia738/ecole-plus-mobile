import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/exams_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/school_year.dart';

/// Agenda des examens / compositions.
class ExamsScreen extends StatefulWidget {
  final bool isParent;
  final bool isTeacher;
  final String? studentId;

  const ExamsScreen({
    super.key,
    this.isParent = false,
    this.isTeacher = false,
    this.studentId,
  });

  factory ExamsScreen.forStudent() =>
      const ExamsScreen(isParent: false, isTeacher: false);

  factory ExamsScreen.forParent({String? studentId}) =>
      ExamsScreen(isParent: true, studentId: studentId);

  factory ExamsScreen.forTeacher() =>
      const ExamsScreen(isTeacher: true);

  @override
  State<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen> {
  List<dynamic> _exams = [];
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
      final year = currentSchoolYear();
      final data = widget.isParent
          ? await ExamsApiService.getMyChild(
              studentId: widget.studentId,
              year: year,
            )
          : await ExamsApiService.getMy(year: year);
      if (mounted) {
        setState(() {
          _exams = data;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Impossible de charger les examens';
          _loading = false;
        });
      }
    }
  }

  String _typeLabel(String? type) => switch (type?.toUpperCase()) {
        'DEVOIR' => 'Devoir',
        'COMPOSITION' => 'Interrogation',
        'EXAMEN' => 'Examen',
        _ => type ?? 'Examen',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Évaluations'),
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
              : _exams.isEmpty
                  ? const Center(
                      child: Text('Aucune évaluation planifiée',
                          style: TextStyle(color: textGrey)),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _exams.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final e = _exams[i];
                          final dateRaw = e['date'] ?? e['scheduledAt'];
                          final dt = DateTime.tryParse(dateRaw?.toString() ?? '');
                          final dateStr = dt != null
                              ? DateFormat('EEE d MMM yyyy', 'fr_FR').format(dt)
                              : '—';
                          final timeStr = dt != null
                              ? DateFormat('HH:mm').format(dt)
                              : null;
                          final subject = e['subject']?.toString() ?? 'Matière';
                          final type = _typeLabel(e['type']?.toString());
                          final room = e['room']?.toString();
                          final className = e['class']?['name']?.toString();

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: primaryBlue.withValues(alpha: 0.15)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 52,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 6),
                                  decoration: BoxDecoration(
                                    color: primaryBlue.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    children: [
                                      if (dt != null) ...[
                                        Text(
                                          DateFormat('d').format(dt),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: primaryBlue,
                                          ),
                                        ),
                                        Text(
                                          DateFormat('MMM', 'fr_FR').format(dt),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: textGrey,
                                          ),
                                        ),
                                      ] else
                                        const Icon(Icons.event_outlined,
                                            color: primaryBlue),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(subject,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14)),
                                      const SizedBox(height: 2),
                                      Text('$type • $dateStr${timeStr != null ? ' à $timeStr' : ''}',
                                          style: const TextStyle(
                                              fontSize: 12, color: textGrey)),
                                      if (room != null && room.isNotEmpty)
                                        Text('Salle $room',
                                            style: const TextStyle(
                                                fontSize: 11, color: textGrey)),
                                      if (className != null &&
                                          className.isNotEmpty &&
                                          widget.isTeacher)
                                        Text(className,
                                            style: const TextStyle(
                                                fontSize: 11, color: textGrey)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
