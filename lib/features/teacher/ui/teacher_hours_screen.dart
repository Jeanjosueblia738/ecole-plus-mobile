import 'package:flutter/material.dart';
import '../../../core/services/finance_api_service.dart';
import '../../../core/theme/app_colors.dart';

/// Pointe début/fin + récap heures du mois (enseignant)
class TeacherHoursScreen extends StatefulWidget {
  const TeacherHoursScreen({super.key});

  @override
  State<TeacherHoursScreen> createState() => _TeacherHoursScreenState();
}

class _TeacherHoursScreenState extends State<TeacherHoursScreen> {
  bool _loading = true;
  List<dynamic> _occurrences = [];
  Map<String, dynamic>? _me;
  String? _busyId;

  Future<void> _load() async {
    setState(() => _loading = true);
    final now = DateTime.now();
    try {
      final occ = await FinanceApiService.listOccurrences(
        year: now.year,
        month: now.month,
      );
      final sum = await FinanceApiService.hoursSummary(
        year: now.year,
        month: now.month,
      );
      final teachers = (sum['teachers'] as List?) ?? [];
      setState(() {
        _occurrences = occ;
        _me = teachers.isNotEmpty
            ? Map<String, dynamic>.from(teachers.first as Map)
            : null;
      });
    } catch (_) {
      setState(() {
        _occurrences = [];
        _me = null;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _fmt(num n) =>
      '${n.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} FCFA';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text('Mes heures'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_me != null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Prévu',
                            value: '${_me!['plannedMinutes']} min',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatCard(
                            label: 'Fait',
                            value: '${_me!['taughtMinutes']} min',
                            color: successGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Manqué',
                            value: '${_me!['shortfallMinutes']} min',
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatCard(
                            label: 'Retenue est.',
                            value: _fmt((_me!['estimatedDeductionXof'] as num?) ?? 0),
                            color: dangerRed,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_occurrences.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Aucune séance ce mois. La direction doit générer les séances depuis l’emploi du temps.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: textGrey),
                      ),
                    ),
                  ..._occurrences.map((raw) {
                    final o = Map<String, dynamic>.from(raw as Map);
                    final id = o['id']?.toString() ?? '';
                    final status = o['status']?.toString() ?? '';
                    final cls = o['class'] is Map
                        ? (o['class'] as Map)['name']
                        : null;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text('${o['subject']} · ${cls ?? ''}'),
                        subtitle: Text(
                          '${o['startTime']}-${o['endTime']} · prévu ${o['plannedMinutes']} min · $status'
                          '${o['actualMinutes'] != null ? ' · fait ${o['actualMinutes']} min' : ''}',
                        ),
                        trailing: status == 'SCHEDULED'
                            ? TextButton(
                                onPressed: _busyId == id
                                    ? null
                                    : () async {
                                        setState(() => _busyId = id);
                                        try {
                                          await FinanceApiService.clockIn(id);
                                          await _load();
                                        } finally {
                                          if (mounted) {
                                            setState(() => _busyId = null);
                                          }
                                        }
                                      },
                                child: const Text('Début'),
                              )
                            : status == 'IN_PROGRESS'
                                ? TextButton(
                                    onPressed: _busyId == id
                                        ? null
                                        : () async {
                                            setState(() => _busyId = id);
                                            try {
                                              await FinanceApiService.clockOut(
                                                  id);
                                              await _load();
                                            } finally {
                                              if (mounted) {
                                                setState(() => _busyId = null);
                                              }
                                            }
                                          },
                                    child: const Text('Fin'),
                                  )
                                : null,
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: textGrey)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color ?? textDark,
            ),
          ),
        ],
      ),
    );
  }
}
