import 'package:flutter/material.dart';
import '../../../core/services/auth_storage_service.dart';
import '../../../core/services/finance_api_service.dart';
import '../../../core/theme/app_colors.dart';
import 'teacher_qr_scan_screen.dart';

/// Pointe via QR + récap heures du mois (enseignant)
class TeacherHoursScreen extends StatefulWidget {
  const TeacherHoursScreen({super.key});

  @override
  State<TeacherHoursScreen> createState() => _TeacherHoursScreenState();
}

class _TeacherHoursScreenState extends State<TeacherHoursScreen> {
  bool _loading = true;
  List<dynamic> _occurrences = [];
  Map<String, dynamic>? _me;
  String? _error;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final now = DateTime.now();
    try {
      final myId = await AuthStorageService.getUserId();
      final occ = await FinanceApiService.listOccurrences(
        year: now.year,
        month: now.month,
      );
      final sum = await FinanceApiService.hoursSummary(
        year: now.year,
        month: now.month,
      );
      final teachers = (sum['teachers'] as List?) ?? [];
      Map<String, dynamic>? me;
      if (teachers.isNotEmpty) {
        Map<String, dynamic>? match;
        if (myId != null && myId.isNotEmpty) {
          for (final t in teachers) {
            final m = Map<String, dynamic>.from(t as Map);
            if (m['teacherId']?.toString() == myId) {
              match = m;
              break;
            }
          }
        }
        me = match ?? Map<String, dynamic>.from(teachers.first as Map);
      }
      setState(() {
        _occurrences = occ;
        _me = me;
      });
    } catch (e) {
      setState(() {
        _occurrences = [];
        _me = null;
        _error = e.toString().replaceFirst('Exception: ', '');
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

  Future<void> _openScanner() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const TeacherQrScanScreen(),
      ),
    );
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text('Mes heures'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Scanner QR classe',
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _openScanner,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scanner QR'),
        onPressed: _openScanner,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F0FE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Pointez en scannant le QR collé sur le bureau de la classe. '
                      '1er scan = arrivée, 2e scan = fin. Les heures sont en GMT Côte d’Ivoire (serveur).',
                      style: TextStyle(fontSize: 13, color: textDark),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: dangerRed),
                      ),
                    ),
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
                            value: _fmt(
                                (_me!['estimatedDeductionXof'] as num?) ?? 0),
                            color: dangerRed,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_occurrences.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _error != null
                            ? 'Impossible de charger les séances.'
                            : 'Aucune séance ce mois. La direction doit générer les séances depuis l’emploi du temps.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: textGrey),
                      ),
                    ),
                  ..._occurrences.map((raw) {
                    final o = Map<String, dynamic>.from(raw as Map);
                    final status = o['status']?.toString() ?? '';
                    final cls = o['class'] is Map
                        ? (o['class'] as Map)['name']
                        : null;
                    final source = o['clockSource']?.toString();
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text('${o['subject']} · ${cls ?? ''}'),
                        subtitle: Text(
                          '${o['startTime']}-${o['endTime']} · prévu ${o['plannedMinutes']} min · $status'
                          '${o['actualMinutes'] != null ? ' · fait ${o['actualMinutes']} min' : ''}'
                          '${o['room'] != null ? ' · ${o['room']}' : ''}'
                          '${source != null ? ' · $source' : ''}',
                        ),
                        trailing: status == 'SCHEDULED'
                            ? const Icon(Icons.qr_code_2, color: textGrey)
                            : status == 'IN_PROGRESS'
                                ? const Icon(Icons.timer, color: Colors.orange)
                                : status == 'COMPLETED'
                                    ? const Icon(Icons.check_circle,
                                        color: successGreen)
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
